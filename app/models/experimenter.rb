class Experimenter
  attr_accessor :source_ontology, :target_ontology, :reference_exists, :matcher, :reference, :reference_path
  
  def self.csv_header
    ["ontologies", "NC_O1", "NC_O2", "NUC_O1", "NUC_O2", "NMC_O1", "NMC_O2", "NRC_O1", "NRC_O2", "PRECISION", "RECALL", "F1"]
  end
  
  def initialize(source, target)
    @source_ontology = source
    @target_ontology = target
    check_reference_alignment!
  end
  
  # builds patterns that utilize the range of relations
  def build_range_patterns
    matched_classes.each do |mc|
      source_ontology.outgoing_relations(mc).each do |rel_out|
        Pattern.n_r_n_pattern(source_ontology, mc, rel_out.url, rel_out.range.to_s, "Range Pattern")
      end
    end
  end
  
  # builds patterns that try to utilize the domain of relations
  def build_domain_patterns
    matched_classes.each do |mc|
      source_ontology.incoming_relations(mc).each do |rel_in|
        Pattern.n_r_n_pattern(source_ontology, rel_in.domain.to_s, rel_in.url, mc, "Domain Pattern")
      end
    end
  end
  
  # removes all existing patterns
  def cleanup_patterns!
    Pattern.all.each{|pattern| pattern.destroy}
  end
  
  # takes the current status quo and let's users provide their input regarding all patterns
  def match!
    user_interactions = 0
    Pattern.each do |pattern|
      pattern.pattern_elements.each do |pe|
        know_matches = matcher.substitutes_for([pe])
        if known_matches.blank?
          user_matches = reference.substitutes_for([pe])
          user_interactions += user_matches.size
          # TODO: add the provided matches to the computed alignment
        end
        # TODO: run the inference engine here!
      end
    end
    return user_interactions
  end
  
  def matched_classes
    matcher.matched_concepts[:source_ontology].to_a & source_ontology.all_concepts[RDF::OWL.Class.to_s].to_a
  end
  
  # ORACLE helpers
  def do_you_know_more?
    matcher.matched_concepts[:correspondence_count] < reference.matched_concepts[:correspondence_count]
  end
  
  def do_i_know_more?
    matcher.matched_concepts[:correspondence_count] > reference.matched_concepts[:correspondence_count]
  end
  
  def call_it_a_tie?
    matcher.matched_concepts[:correspondence_count] == reference.matched_concepts[:correspondence_count]
  end
    
  def alignment_info
    info = ["#{source_ontology.very_short_name}-#{target_ontology.very_short_name}"]
    return info.concat(ontology_stats).concat(matching_stats).concat(alignment_stats)
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
      target_concepts[:all].size,
      source_concepts[:all].size - matcher.matched_concepts[:source_ontology].size,
      target_concepts[:all].size - matcher.matched_concepts[:target_ontology].size
    ]
  end
  
  def matching_stats
    [
      matcher.matched_concepts[:source_ontology].size,
      matcher.matched_concepts[:target_ontology].size,
      reference.matched_concepts[:source_ontology].size,
      reference.matched_concepts[:target_ontology].size
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
end