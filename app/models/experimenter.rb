class Experimenter
  # the basics
  attr_accessor :source_ontology, :target_ontology, :reference_exists, :matcher, :reference, :reference_path, :invert
  attr_accessor :matched_concepts, :visited_concepts, :to_test, :unseen_concepts, :use_class_relationships, :use_attributes

  def self.run_experiment(source_ontology, target_ontology, experiment, modifiers)
    expi1 = self.new(source_ontology, target_ontology)
    return nil unless expi1.go_on?
    expi2 = self.new(target_ontology, source_ontology)

    puts ""
    # experiment one: source-target using only concepts from source
    puts "**** Starting Experiment: #{expi1.ont_field}, #{experiment || 'complete'} ****"
    stats1 = expi1.run!(experiment, modifiers)
    row1 = expi1.csv_for_stats(stats1)
    puts "==== results: #{row1} #{stats1} ===="
    expi1.matcher.delete_alignment!

    # experiment two: target-source using only concepts from target
    puts "**** Starting Experiment: #{expi2.ont_field}, #{experiment || 'complete'} ****"
    stats2 = expi2.run!(experiment, modifiers)
    row2 = expi2.csv_for_stats(stats2)
    puts "==== results: #{row2} #{stats2} ===="
    expi2.matcher.delete_alignment!  
    
    # experiment three: source-target using concepts from both ontologies
    expi3 = self.new(source_ontology, target_ontology)
    puts "**** rerunning experiment: #{expi3.ont_field}, #{experiment || 'complete'} ****"    
    stats3 = expi3.run!(experiment, modifiers, true)
    row3 = expi3.csv_for_stats(stats3)
    puts "==== results: #{row3} #{stats3} ===="

    
    # only keep the maximum expansion of the computed alignment and the minimum of missing alignments 
    if experiment.nil? && modifiers.all?{|m,k| k == true}
      target_path = Rails.root.join("eswc_2015", "computed_alignments", expi3.matcher.alignment_path.split("/").last)
      FileUtils.mv(expi3.matcher.alignment_path, target_path, :force => true)
      File.open("eswc_2015/missing_alignments/#{expi3.matcher.alignment_path.split("/").last}", "w+") do |f|
        expi3.missing_correspondences.each{|mc| f.puts mc}
      end      
    else
      expi3.matcher.delete_alignment!
    end
    
    # return all three 'rows', which are actually combinations of columns
    return row1 + row2 + row3
  end

  def initialize(source, target)
    @source_ontology = source
    @target_ontology = target
    @use_class_relationships = false
    @use_attributes = false
    @invert = false
    check_reference_alignment!
  end
  
  def self.experiments
    return [
      :include_superclasses!,
      :include_subclasses!,
      :include_siblings!,
      :go_really_deep!,
      :build_range_patterns!,
      :build_domain_patterns!,
      :build_relation_patterns!,
      :build_attribute_patterns!,
      :build_classes!
    ]
  end
  
  def reference_properties
    stats = {}
    [source_ontology, target_ontology].each do |ont|
      key = key_for_ontology(ont)
      mc = reference.matched_concepts[key] & ont.all_concepts[RDF::OWL.Class.to_s].to_a
      mr = reference.matched_concepts[key] & ont.all_concepts[RDF::OWL.ObjectProperty.to_s].to_a
      ma = reference.matched_concepts[key] & ont.all_concepts[RDF::OWL.DatatypeProperty.to_s].to_a
      
      stats[ont.url] = {
        :classes => mc.size, 
        :relations => mr.size, 
        :attributes => ma.size, 
        :connections => {}
      }
      
      mc.each do |matched_class|
        stats[ont.url][:connections][matched_class] = {
          :class_rels => Set.new, :rels => Set.new, :attribs => Set.new, :one_hops => Set.new
        }
        stat = stats[ont.url][:connections][matched_class]
        
        ont_class = ont.classes.find{|cla| cla.class_url == matched_class}
        # all sub and superclass relations
        stat[:class_rels] = mc.select{|mmc| ont_class.has_class_relation_with?(mmc)}
        # all incmoing and outgoing relations
        incoming_relations = ont.incoming_relations(matched_class).select{|mcr| mr.include?(mcr.relation_url)}
        outgoing_relations = ont.outgoing_relations(matched_class).select{|mcr| mr.include?(mcr.relation_url)}
        (incoming_relations + outgoing_relations).each do |rel|
          stat[:rels] << rel.relation_url
          stats[ont.url][:connections][rel.relation_url] = {:rels => [matched_class]}
        end
        # all one hop connection
        domains = ont.incoming_relations(matched_class).select{|ir| mc.include?(ir.domain)}
        ranges = ont.outgoing_relations(matched_class).select{|orr| mc.include?(orr.range)}
        stat[:one_hops].merge(domains).merge(ranges)
        # all_attributes
        attribs = ont.attributes_of(matched_class).select{|mca| ma.include?(mca)}
        stat[:attribs] = attribs
        attribs.each{|attrib| stats[ont.url][:connections][attrib] = {:attribs => [matched_class]}}
      end
      
      stats[ont.url][:connections].select{|k,v| v.all?{|kk,vv| vv.empty?}}.each do |k,v|
        puts "no connection found for #{k}"
      end
    end
    return stats
  end
  
  #def self.modifier_combinations
  #  [
  #    {:@use_attributes => true, :@use_class_relationships => true},      
  #    {:@use_attributes => true, :@use_class_relationships => false},      
  #    {:@use_attributes => false, :@use_class_relationships => true},
  #    {:@use_attributes => false, :@use_class_relationships => false}
  #  ]
  #end
  
  def run!(experiment, modifiers, use_both = false)
    initialize_experiment!(use_both, modifiers)
    
    # save missing as it naturally changes during matching...
    all_concepts = matched_concepts.keys.collect{|ontology| ontology.all_concepts[:all].size}.min()
    # build the initial stats
    stats = {
      :missing_correspondences => missing_correspondences.size.to_i, 
      :excess_correspondences => excess_correspondences.size.to_i
    }
    
    i = 1
    loop do
      matched_concepts.each_pair do |ontology, concepts_hash|
        log "building patterns with #{ontology.very_short_name}: #{concepts_hash}"
      end
      build_patterns!(experiment)
      log "unseen concepts (#{unseen_concepts.size}): #{unseen_concepts.to_a}"      
      clear_matched_concepts!
      stats.merge!(match!){|key,val1,val2| val1+val2}
      break unless more_concepts_available?
    end
        
    stats[:test_selection] = visited_concepts.size
    found_correspondences = stats[:matches] + stats[:removals]
    stats[:interaction_expectancy] = (found_correspondences * (stats[:test_selection].to_f + 1) / (found_correspondences.to_f + 1)).round
    stats[:baseline] = (found_correspondences * (all_concepts.to_f + 1) / (stats[:missing_correspondences].to_f + 1)).round
    return stats
  end
  
  def initialize_experiment!(use_both, modifiers)
    log "To recreate e = Experimenter.new(Ontology.find(#{source_ontology.id}), Ontology.find(#{target_ontology.id}))"
    @to_test = Set.new()
    @visited_concepts = {}
    @unseen_concepts = Set.new
    modifiers.each_pair{|m, v| self.instance_variable_set(m, v)}
    matcher.match!
    log "Matcher Config: #{matcher.source_ontology.very_short_name} - #{matcher.target_ontology.very_short_name}, invert: #{invert}"    
    log "modifiers: #{modifiers}"
    use_them_to_create_patterns = use_both ? [source_ontology, target_ontology] : [source_ontology]
    prepare_matched_concepts!(use_them_to_create_patterns)
  end
  
  def build_patterns!(method)
    matched_concepts.keys.each do |ontology|
      if method.nil?
        self.class.experiments.compact.each{|exp| self.send(exp, ontology)}
      else
        self.send(method, ontology)
      end
    end
  end

  # takes the current status quo and let's users provide their input regarding all patterns
  def match!()
    log "== Matching on #{to_test.size} concepts =="
    interactions = blank_interactions
    to_test.each do |concept|
      next if visited_concepts[concept]
      interactions.merge!(get_stats_for_concept(concept)) {|key,val1,val2| val1+val2}
      visited_concepts[concept] = true
    end
    return interactions
  end
  
  def blank_interactions
    {:matches => 0, :removals => 0, :no_idea => 0}
  end
  
  def get_stats_for_concept(concept)
    interactions = blank_interactions
    
    # first aml, then the user
    known_matches = matcher.get_simple_correspondences(concept)
    user_matches = reference.get_simple_correspondences(concept)
    
    # all that are not already in the known matches will be added
    new_ones = user_matches.select{|um| known_matches.find{|km| km.equal_to?(um)}.nil?}
    new_ones.each{|no|
      add_new_correspondence!(matcher.add_correspondence!(no))
      log "!! found new user match: #{no.entity1}-#{no.entity2} !!"
      interactions[:matches] += 1
    }
    
    # all that are know but not by the oracle, will be removed
    false_positives = known_matches.select{|km| user_matches.find{|um| um.equal_to?(km)}.nil?}
    false_positives.each{|fp| 
      log "?? removing false positive: #{fp.entity1}-#{fp.entity2} ??"
      matcher.remove_correspondence!(fp)
      interactions[:removals] += 1
    }
    
    interactions[:no_idea] += 1 if false_positives.empty? && new_ones.empty? && known_matches.empty?
    return interactions
  end  
  
  def prepare_matched_concepts!(ontologies)
    @matched_concepts = {}
    ontologies.each do |ont|
      @matched_concepts[ont] = {
        :attributes => matched_attributes(ont, key_for_ontology(ont)), 
        :relations => matched_relations(ont, key_for_ontology(ont)), 
        :classes => matched_classes(ont, key_for_ontology(ont)),
      }
    end
  end
  
  def clear_matched_concepts!()
    matched_concepts.each_pair{|ontology, hash| hash.each_pair{|key, concepts| hash[key] = []}}
  end
  
  def matched_classes(ontology, key)
    matcher.matched_concepts[key] & ontology.all_concepts[RDF::OWL.Class.to_s].to_a
  end
  
  def matched_relations(ontology, key)
    matcher.matched_concepts[key] & ontology.all_concepts[RDF::OWL.ObjectProperty.to_s].to_a
  end
  
  def matched_attributes(ontology, key)
    matcher.matched_concepts[key] & ontology.all_concepts[RDF::OWL.DatatypeProperty.to_s].to_a
  end  
  
  def more_concepts_available?
    matched_concepts.collect{|ont, hash| hash.values.all?{|concepts| !concepts.empty?}}.any?{|val| val == true}
  end
  
  # we count a) all correspondences the matcher doesn't know, yet, and b) the ones that are exc
  def missing_correspondences
    reference.all_correspondences - matcher.all_correspondences
  end
  
  def excess_correspondences
    matcher.all_correspondences - reference.all_correspondences
  end
    
  def add_new_correspondence!(concept)
    matched_concepts.keys.each do |ontology|
      pe = ontology.element_class_for_rdf_type(concept).class
      key = case pe
        when Node.class then :classes
        when AttributeConstraint.class then :attributes
        when RelationConstraint.class then :relations
      end
      
      unless key.nil?
        "added new #{key} #{concept} for #{ontology.very_short_name}"
        matched_concepts[ontology][key] << concept
        return
      end
    end
    raise "Could not find #{concept} in either ontology"
  end
  
  def build_range_patterns!(ontology)
    # all outgoing relations
    matched_concepts[ontology][:classes].each do |mc|
      add_test!(mc)
      ontology.outgoing_relations(mc).each do |rel_out|
        add_test!(rel_out.url)
        add_test!(rel_out.domain)
        add_attributes_for_class!(mc, ontology)
        add_attributes_for_class!(rel_out.domain, ontology)
      end
    end
  end
  
  def build_domain_patterns!(ontology)
    # and all incoming ones
    matched_concepts[ontology][:classes].each do |mc| 
      add_test!(mc)
      ontology.incoming_relations(mc).each do |rel_in|
        add_test!(rel_in.url)
        add_test!(rel_in.range)
        add_attributes_for_class!(mc, ontology)
        add_attributes_for_class!(rel_in.range, ontology)
      end
    end
  end
  
  def add_attributes_for_class!(mc, ontology)
    return unless use_attributes
    ontology.attributes_of(mc).each do |attrib|
      add_test!(attrib)
    end
  end
  
  def build_relation_patterns!(ontology)
    matched_concepts[ontology][:relations].each do |rel|
      add_test!(rel)
      domains, ranges = ontology.relation_information(rel)
      domains.each{|domain| add_test!(domain)}
      ranges.each{|range| add_test!(range)}
    end
  end
  
  def build_attribute_patterns!(ontology)
    matched_concepts[ontology][:attributes].each do |ma|
      add_test!(ontology.domain_for_attribute(ma))
      add_test!(ma)
    end
  end
  
  def build_classes!(ontology)
    matched_concepts[ontology][:classes].each do |mc|
      add_test!(mc)
    end
  end
  
  # determines the lookup key for each ontology
  def key_for_ontology(ontology)
    matcher.source_ontology == ontology ? :source : :target
  end
  
  def add_test!(concept)
    return if concept.start_with?("_:")
    to_test << concept
    matched_concepts.each_pair do |ontology, concept_hash|
      add_sub_and_superclass_tests!(ontology, concept)
      return if !concept_hash.find{|key, concepts| concepts.include?(concept)}.nil?
    end
    unseen_concepts << concept
  end
  
  def add_sub_and_superclass_tests!(ontology, concept)
    return unless use_class_relationships
    clazz = ontology.classes.find{|cla| cla.class_url == concept}
    unless clazz.nil?
      to_test.merge(clazz.all_superclasses) #.each{|sc|  << sc.class_url}
      to_test.merge(clazz.all_subclasses) #.each{|sc| to_test << sc.class_url}
      to_test.merge(clazz.all_siblings)
    end
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
    [
      invert ? target_ontology.all_concepts[:all].size : source_ontology.all_concepts[:all].size,
      invert ? source_ontology.all_concepts[:all].size : target_ontology.all_concepts[:all].size
    ]
  end

  def matching_stats
    [
      matcher.matched_concepts[key_for_ontology(source_ontology)].size,
      matcher.matched_concepts[key_for_ontology(target_ontology)].size,
      reference.matched_concepts[key_for_ontology(source_ontology)].size,
      reference.matched_concepts[key_for_ontology(target_ontology)].size,
      missing_correspondences.size.to_i,
      excess_correspondences.size.to_i
    ]
  end

  def matcher
    if @matcher.nil?
      @matcher = OntologyMatcher.new(@source_ontology, @target_ontology, true)
      @matcher.invert! if invert
    end
    return @matcher
  end

  def reference
    if @reference.nil?
      @reference = OntologyMatcher.new(@source_ontology, @target_ontology, true)
      @reference.invert! if invert
      @reference.alignment_path = reference_path
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
        @reference_exists = true
        @invert = true
      else
        @reference_exists = false
      end
    end
  end
  
  def log(txt)
    puts txt
  end
  
  
  def csv_for_stats(stats)
    return [
      stats[:matches] + stats[:removals],
      stats[:test_selection],
      stats[:interaction_expectancy],
      stats[:baseline],
      stats[:matches],
      stats[:removals]
    ].concat(alignment_stats)
  end
  
  def self.experiment_header
    return ["_L", "_R", ""].collect{|suf|
      [
        "#Found#{suf}",
        "Sample_Size",
        "Expectancy#{suf}",
        "Baseline",
        "#Additions#{suf}",
        "#Removals#{suf}",
        "Precision_new#{suf}",
        "Recall_New#{suf}",
        "F-Measure_new#{suf}"
      ]
    }.flatten
  end
  
  def self.csv_header
    [
      "ontologies", 
      "#Concepts_O1", 
      "#Concepts_O2", 
      "#Corr_O1",
      "#Corr_O2",
      "#Ref_Corr_O1",
      "#Ref_Corr_O2",
      "#Missing_Corr",
      "#False_Corr",
      "Precision",
      "Recall",
      "F-Measure"
    ]
  end
end
