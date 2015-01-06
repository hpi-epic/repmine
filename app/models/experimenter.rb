class Experimenter
  # the basics
  attr_accessor :source_ontology, :target_ontology, :reference_exists, :matcher, :reference, :reference_path
  attr_accessor :matched_concepts, :learnings, :visited_concepts

  def initialize(source, target)
    @source_ontology = source
    @target_ontology = target
    reset_learnings!    
    check_reference_alignment!
  end
  
  def reset_learnings!
    @learnings = {:attributes => [], :relations => [], :classes => []}
  end
  
  def matched_concepts
    @matched_concepts ||= {:attributes => matched_attributes, :relations => matched_relations, :classes => matched_classes}        
  end
  
  def build_range_patterns!(attributes = false)
    # all outgoing relations
    matched_concepts[:classes].each do |mc|
      source_ontology.outgoing_relations(mc).each do |rel_out|    
        pattern = Pattern.n_r_n_pattern(source_ontology, mc, rel_out.url, rel_out.range.to_s, "Range Pattern")
        add_attributes_to_pattern!(pattern) if attributes
      end
    end
  end
  
  def build_domain_patterns!(attributes = false)
    # and all incoming ones
    matched_concepts[:classes].each do |mc|    
      source_ontology.incoming_relations(mc).each do |rel_in|
        pattern = Pattern.n_r_n_pattern(source_ontology, rel_in.domain.to_s, rel_in.url, mc, "Domain Pattern")
        add_attributes_to_pattern!(pattern) if attributes
      end
    end
  end
  
  def add_attributes_to_pattern!(pattern)
    pattern.nodes.each do |node|
      source_ontology.attributes_of(node.rdf_type).each do |attrib|
        ac = node.attribute_constraints.create!
        ac.rdf_type = attrib
      end
    end
  end
  
  def build_relation_patterns!
    puts "building relation patterns for #{matched_concepts[:relations].size} relations"
    matched_concepts[:relations].each do |rel|
      domain, range = source_ontology.relation_information(rel)
      Pattern.n_r_n_pattern(source_ontology, domain, rel, range, "Relation Pattern")
    end
  end
  
  def build_attribute_patterns!
    puts "building attribute patterns for #{matched_concepts[:attributes].size} attributes"
    matched_attributes.each do |ma|
      Pattern.n_a_pattern(source_ontology, ma, source_ontology.domain_for_attribute(ma), "Attribute Pattern")
    end
  end

  # removes all existing patterns
  def cleanup!
    Pattern.destroy_all
    PatternElement.destroy_all
    OntologyCorrespondence.destroy_all
  end
  
  def run!()
    i = 1
    interactions = {}
    @visited_concepts = {}
    
    loop do
      cleanup!
      build_patterns!
      interactions.merge!(match!){|key,val1,val2| val1+val2}
      break if learnings.values.all?{|e| e.empty?}
      @matched_concepts = @learnings
      puts "round no #{i+=1} with #{matched_concepts}"
      reset_learnings!
    end
    
    return interactions
  end
  
  def build_patterns!
    build_range_patterns!
    build_domain_patterns!    
    build_relation_patterns!
    build_attribute_patterns!
  end
  
  def are_we_done_yet?
    mc = matcher.all_correspondences
    rc = reference.all_correspondences
    return (mc - rc).empty? && (rc - mc).empty?
  end

  # takes the current status quo and let's users provide their input regarding all patterns
  def match!()
    interactions = {:matches => 0, :removals => 0, :no_idea => 0}
    Pattern.all.each do |pattern|
      pattern.pattern_elements.each do |pe|
        next unless visited_concepts[pe.rdf_type].nil?
        interactions.merge!(get_stats_for_pattern_element(pe)) {|key,val1,val2| val1+val2}
        visited_concepts[pe.rdf_type] = true
      end
    end
    return interactions
  end
  
  def get_stats_for_pattern_element(pe)
    interactions = {:matches => 0, :removals => 0, :no_idea => 0}
    
    # first aml, then the user
    known_matches = matcher.get_simple_correspondences(pe)
    user_matches = reference.get_simple_correspondences(pe, false)
    
    # all that are not already in the known matches will be added
    new_ones = user_matches.select{|um| known_matches.find{|km| km.equal_to?(um)}.nil?}
    new_ones.each{|no| 
      puts "!! found new user match: #{no.entity1}-#{no.entity2} !!"
      add_new_correspondence!(matcher.add_correspondence!(no))
    }
    interactions[:matches] += new_ones.size
    
    # all that are know but not by the oracle, will be removed
    false_positives = known_matches.select{|km| user_matches.find{|um| um.equal_to?(km)}.nil?}
    false_positives.each{|fp| 
      puts "?? removing false positive: #{fp.entity1}-#{fp.entity2} ??"  
      matcher.remove_correspondence!(fp)
    }
    interactions[:removals] += false_positives.size
    interactions[:no_idea] += 1 if false_positives.empty? && new_ones.empty? && known_matches.empty?
    return interactions
  end
  
  def add_new_correspondence!(pe)
    key = case pe 
      when Node then :classes
      when AttributeConstraint then :attributes
      when RelationConstraint then :relations
    end
    puts "adding #{pe.rdf_type} to known #{key}"
    learnings[key] << pe.rdf_type
  end

  def matched_classes
    matcher.matched_concepts[:source_ontology] & source_ontology.all_concepts[RDF::OWL.Class.to_s].to_a
  end
  
  def matched_relations
    matcher.matched_concepts[:source_ontology] & source_ontology.all_concepts[RDF::OWL.ObjectProperty.to_s].to_a
  end
  
  def matched_attributes
    matcher.matched_concepts[:source_ontology] & source_ontology.all_concepts[RDF::OWL.DatatypeProperty.to_s].to_a
  end
  
  # we count a) all correspondences the matcher doesn't know, yet and b) all correspondences that are excess
  def missing_correspondences
    reference.all_correspondences - matcher.all_correspondences # + (matcher.all_correspondences - reference.all_correspondences)
  end
  
  # this is a negative hypergeometric distribution. i.e., expectancy is missing_concepts * (open_concepts + 1 / missing_concepts +1)
  def expectation_for_random_choice
    missing_concepts = missing_correspondences.collect{|oa| oa[:s]}.uniq.size.to_f
    open_concepts = source_ontology.all_concepts[:all].size.to_f - missing_concepts
    return (missing_concepts * ((open_concepts + 1) / (missing_concepts + 1))).round
  end

  def alignment_info
    info = [ont_field]
    return info.concat(ontology_stats).concat(matching_stats).concat(alignment_stats)
  end
  
  def ont_field
    "#{source_ontology.very_short_name}-#{target_ontology.very_short_name}"
  end

  def alignment_stats
    cmd = "java -cp eswc_2015/alignment_api/lib/procalign.jar "
    cmd += "fr.inrialpes.exmo.align.cli.EvalAlign -i fr.inrialpes.exmo.align.impl.eval.PRecEvaluator"
    parent_path = Rails.root.to_s
    cmd += " file://#{reference_path} file://#{matcher.alignment_path}"
    res = ""
    Open3.popen3(cmd, :chdir => Rails.root.to_s){|stdin, stdout, stderr, wait_thr| res = stdout.read}
    precision = res.scan(/<map:precision>(.*?)<\/map:precision>/).flatten.first.to_f
    recall = res.scan(/<map:recall>(.*?)<\/map:recall>/).flatten.first.to_f
    f1_measure = res.scan(/<map:fMeasure>(.*?)<\/map:fMeasure>/).flatten.first.to_f
    return [precision, recall, f1_measure].collect{|val| val.round(2)}
  end

  def ontology_stats
    source_concepts = source_ontology.all_concepts
    target_concepts = target_ontology.all_concepts
    [
      source_concepts[:all].size,
      target_concepts[:all].size
    ]
  end

  def matching_stats
    [
      matcher.matched_concepts[:source_ontology].size,
      matcher.matched_concepts[:target_ontology].size,
      reference.matched_concepts[:source_ontology].size,
      reference.matched_concepts[:target_ontology].size,
      missing_correspondences.size,
      expectation_for_random_choice
    ]
  end

  def matcher
    if @matcher.nil?
      @matcher = OntologyMatcher.new(@source_ontology, @target_ontology, true)
      @matcher.match!
    end
    return @matcher
  end

  def reference
    if @reference.nil?
      @reference = OntologyMatcher.new(@source_ontology, @target_ontology, true)
      @reference.add_to_alignment_graph!(@reference_path)
    end
    return @reference
  end

  def go_on?
    return reference_exists
  end

  def check_reference_alignment!
    ref_folder = Rails.root.to_s + "/eswc_2015/reference_alignments/"
    @reference_path = ref_folder + @source_ontology.very_short_name + "-" + @target_ontology.very_short_name + ".rdf"
    if File.exist?(@reference_path)
      @reference_exists = true
    else
      @reference_path = ref_folder + @target_ontology.very_short_name + "-" + @source_ontology.very_short_name + ".rdf"
      if File.exist?(@reference_path)
        @source_ontology, @target_ontology = @target_ontology, @source_ontology
        @reference_exists = true
      else
        @reference_exists = false
      end
    end
  end
  
  def self.csv_header
    [
      "ontologies", 
      "#Concepts_O1", 
      "#Concepts_O2", 
      "#Matched_O1", 
      "#Matched_O2", 
      "#Reference_O1", 
      "#Reference_O2", 
      "Missing", 
      "ExpectancyUI", 
      "Precision", 
      "Recall", 
      "F-Measure"
    ]
  end
end
