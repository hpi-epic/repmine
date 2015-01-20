class Experimenter
  # the basics
  attr_accessor :source_ontology, :target_ontology, :reference_exists, :matcher, :reference, :reference_path, :invert
  attr_accessor :matched_concepts, :visited_concepts, :to_test, :new_tests, :hit_concepts, :method_stats

  def self.run_experiment(source_ontology, target_ontology, experiment)
    expi1 = self.new(source_ontology, target_ontology)
    return nil unless expi1.go_on?
    expi2 = self.new(target_ontology, source_ontology)

    puts ""
    # experiment one: source-target using only concepts from source
    puts "**** Starting Experiment: #{expi1.ont_field}, #{experiment} ****"
    stats1, m1_stats = expi1.run!(experiment)
    row1 = expi1.csv_for_stats(stats1)
    puts "==== results: #{row1} #{stats1} ===="
    store_alignment!(expi1, experiment)

    # experiment two: target-source using only concepts from target
    puts "**** Starting Experiment: #{expi2.ont_field}, #{experiment} ****"
    stats2, m2_stats = expi2.run!(experiment)
    row2 = expi2.csv_for_stats(stats2)
    puts "==== results: #{row2} #{stats2} ===="
    store_alignment!(expi2, experiment)

    # only keep the maximum expansion of the computed alignment and the minimum of missing alignments 
    if experiment.size == self.experiments.size
      File.open("eswc_2015/methods/#{expi1.ont_field}.yml", "w+"){|f|
        f.puts m1_stats.to_yaml
        f.puts m2_stats.to_yaml
      }
    end
    
    min_stats = [m1_stats[:min_costs], numberize(m1_stats[:min_paths]), m2_stats[:min_costs], numberize(m2_stats[:min_paths])]
    
    # return all three 'rows', which are actually combinations of columns
    return row1 + row2 + min_stats, m1_stats, m2_stats
  end
  
  def self.numberize(paths)
    return "" if paths.empty?
    return paths.collect{|path| path.collect{|pe| experiments.index(pe) + 1}.sort.join(",")}.collect{|thing| "[#{thing}]"}.join(";")
  end
  
  def self.store_alignment!(expi, experiment)
    if experiment.size != experiments.size
      expi.matcher.delete_alignment!
    else
      target_path = Rails.root.join("eswc_2015", "computed_alignments", expi.ont_field + ".rdf")
      FileUtils.mv(expi.matcher.alignment_path, target_path, :force => true)
      File.open("eswc_2015/missing_alignments/#{expi.ont_field}.txt", "w+") do |f|
        expi.missing_correspondences.each{|mc| f.puts mc}
      end
    end    
  end

  def initialize(source, target)
    @source_ontology = source
    @target_ontology = target
    @use_class_relationships = false
    @use_attributes = false
    @invert = false    
    check_reference_alignment!
  end
  
  # somehow this has still some problems. make sure to manually review the created clusters in eswc_2015/clusters
  def reference_properties
    stats = {}
    [source_ontology, target_ontology].each do |ont|
      key = key_for_ontology(ont)
      mc = reference.matched_concepts[key] & ont.all_concepts[RDF::OWL.Class.to_s].to_a
      mr = reference.matched_concepts[key] & ont.all_concepts[RDF::OWL.ObjectProperty.to_s].to_a
      ma = reference.matched_concepts[key] & ont.all_concepts[RDF::OWL.DatatypeProperty.to_s].to_a
      all_matched_concepts = mc + mr + ma
      
      stats[ont.very_short_name] = {
        :classes => mc.size, 
        :relations => mr.size, 
        :attributes => ma.size, 
        :clusters => []
      }
      
      mc.each_with_index do |matched_class, i|
        cluster = stats[ont.very_short_name][:clusters].find{|c| c.include?(matched_class)}
        if cluster.nil?
          cluster = Set.new([matched_class])
          stats[ont.very_short_name][:clusters] << cluster
        end
        
        ont_class = ont.classes.find{|cla| cla.class_url == matched_class}
        outgoing_relations = ont.outgoing_relations(matched_class)
        
        mc.each do |compare_class|
          cluster << compare_class if ont_class.has_class_relation_with?(compare_class)
          cluster << compare_class if outgoing_relations.any?{|ir| ir.range.include?(compare_class)}
        end
        
        ma.each do |matched_attribute|
          cluster << matched_attribute if ont.domain_for_attribute(matched_attribute) == matched_class
        end
        
        mr.each do |matched_relation|
          ranges, domains = ont.relation_information(matched_relation)
          cluster << matched_relation if ranges.include?(matched_class) || domains.include?(matched_class)
        end
      end
      
      (mr + ma).each do |mc|
        cluster = stats[ont.very_short_name][:clusters].find{|c| c.include?(mc)}
        if cluster.nil?
          cluster = Set.new([mc])
          stats[ont.very_short_name][:clusters] << cluster
        end
        ont.inverse_concepts(mc).each do |inv_concept|
          cluster << inv_concept if all_matched_concepts.include?(inv_concept)
        end
      end

      isolated = stats[ont.very_short_name][:clusters].select{|c| c.size == 1}
      clustered_concepts = stats[ont.very_short_name][:clusters].collect{|c| c.to_a}.flatten
      
      all_concepts_matched = all_matched_concepts.size == clustered_concepts.uniq.size
      forgotten_concepts = all_matched_concepts - clustered_concepts
      excess_concepts = clustered_concepts - all_matched_concepts
      dupes = clustered_concepts.select{|e| clustered_concepts.count(e) > 1 }
      
      raise "odd matching numbers, #{stats[ont.very_short_name][:clusters]}" unless all_concepts_matched
      raise "forgotten the following concepts: #{forgotten_concepts}" unless forgotten_concepts.empty?
      raise "identified too many concepts: #{excess_concepts}" unless excess_concepts.empty?
      stats[ont.very_short_name][:isolated] = isolated
      stats[ont.very_short_name][:cluster_count] = stats[ont.very_short_name][:clusters].size
    end
    File.open("eswc_2015/clusters/#{ont_field}_clusters.yaml", "w+"){|f| f.puts stats.to_yaml}
    return stats
  end
  
  def run!(experiment, use_both = false)
    initialize_experiment!(use_both)
    
    # save missing as it naturally changes during matching...
    matched_concept_count = matched_concepts[source_ontology].values.inject(0){|sum, vals| sum += vals.size}
    puts "we're starting with #{matched_concept_count} concepts, come what may..."
    all_concepts = matched_concepts.keys.collect{|ontology| ontology.all_concepts[:all].size}.min()
    
    those_should_be_hit = matched_concepts.keys.collect{|ontology|
      (missing_correspondences + excess_correspondences).collect{|c| c[key_for_ontology(ontology)]}  
    }.uniq
    
    baseline_concepts = those_should_be_hit.sort_by{|x| x.size}.first
    
    puts "baseline concepts #{baseline_concepts.size}"
    # build the initial stats
    stats = {
      :missing_correspondences => missing_correspondences.size.to_i, 
      :excess_correspondences => excess_correspondences.size.to_i
    }
    
    i = 1
    loop do
      build_patterns!(experiment)
      clear_matched_concepts!
      stats.merge!(match!){|key,val1,val2| val1+val2}
      break unless more_concepts_available?
      puts "-- starting round #{i+=1}"
    end
    
    puts "got hits on #{hit_concepts.size} concepts"
    
    clusterfuck = {}
    method_stats.each_pair do |meth, meth_stats|
      meth_stats[:added_concepts] = meth_stats[:added_concepts].to_a
      meth_stats[:hits] = (baseline_concepts & meth_stats[:added_concepts])
      meth_stats[:hits].each do |hit|
        clusterfuck[hit] ||= Set.new
        clusterfuck[hit] << meth
      end
    end
    
    costs, min_paths = determine_minimal_set(method_stats, clusterfuck)
    method_stats[:min_costs] = costs + matched_concept_count
    method_stats[:min_paths] = min_paths
    puts "found #{min_paths.size} minimal paths. min_cost: #{method_stats[:min_costs]}, #{min_paths}, #{clusterfuck}"

    stats[:test_selection] = visited_concepts.size
    found_correspondences = stats[:matches] + stats[:removals]
    stats[:interaction_expectancy] = (hit_concepts.size * (stats[:test_selection].to_f + 1) / (hit_concepts.size.to_f + 1)).round
    stats[:baseline] = (hit_concepts.size * (all_concepts.to_f + 1) / (baseline_concepts.size + 1)).round
    return stats, method_stats
  end
  
  def baseline_concepts(ontology)
    return (missing_correspondences + excess_correspondences).collect{|c| c[key_for_ontology(ontology)]}.uniq
  end
  
  def determine_minimal_set(method_stats, clusterfuck)
    paths = Set.new()
    
    unique_methods = clusterfuck.values.collect{|val| val.to_a}.flatten.uniq
    unique_methods.each do |meth|
      paths.merge(create_valid_paths([meth], unique_methods, clusterfuck))
    end
    
    puts "found #{paths.size} paths, now determining ones with lowest costs"
    paths = paths.to_a.uniq
    costs = paths.collect{|combi| combi.inject(0){|sum, method| sum += method_stats[method][:added_concepts].size}}
    minimal_paths = costs.each.with_index.find_all{ |a,i| a == costs.min }.map{ |a,b| paths[b].uniq }.uniq
    return costs.min || 0, minimal_paths
  end
  
  def create_valid_paths(path_so_far, methods, cluster)
    paths = Set.new()
    if cluster.any?{|concept, meths| (meths & path_so_far).empty?}
      (methods - path_so_far).each do |next_method|
        paths.merge(create_valid_paths(path_so_far + [next_method], methods, cluster))
      end
    else
      paths << path_so_far.sort
    end
    return paths
  end
  
  def initialize_experiment!(use_both)
    log "To recreate e = Experimenter.new(Ontology.find(#{source_ontology.id}), Ontology.find(#{target_ontology.id}))"
    @to_test = Set.new
    @visited_concepts = {}
    @hit_concepts = Set.new
    @method_stats = {}
    matcher.match!
    log "Matcher Config: #{matcher.source_ontology.very_short_name} - #{matcher.target_ontology.very_short_name}, invert: #{invert}"    
    use_them_to_create_patterns = use_both ? [source_ontology, target_ontology] : [source_ontology]
    prepare_matched_concepts!(use_them_to_create_patterns)
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
      matcher.add_correspondence!(no)
      add_new_correspondence!(no.entity1)
      add_new_correspondence!(no.entity2)
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
    hit_concepts << concept if !false_positives.empty? || !new_ones.empty?
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
    matched_concepts.collect{|ont, hash| hash.values.any?{|concepts| !concepts.empty?}}.any?{|val| val == true}
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
      pe = ontology.element_class_for_rdf_type(concept).name
      
      key = case pe
        when "Node" then :classes
        when "AttributeConstraint" then :attributes
        when "RelationConstraint" then :relations
      end
      
      unless key.nil?
        #puts "adding new #{key} #{concept}"
        matched_concepts[ontology][key] << concept
        return
      end
    end
  end
  
  def build_patterns!(methods)
    matched_concepts.keys.each do |ontology|
      blank!(ontology)
      methods.each do |meth|
        @new_tests = Set.new
        self.send(meth, ontology)
        puts "#{meth} added #{new_tests.size} new concepts"
        to_test.merge(new_tests)
        method_stats[meth] ||= {:added_concepts => Set.new}
        method_stats[meth][:added_concepts].merge(new_tests)
      end
    end
  end
  
  def self.experiments
    return [
      :include_superclasses!,
      :include_subclasses!,
      :include_siblings!,
      :go_really_deep!,
      :include_attributes!,
      :build_range_patterns!,
      :build_domain_patterns!,
      :build_relation_patterns!,
      :build_attribute_patterns!,
      :include_inverse_properties!,
      :include_subproperties!,
      :include_equivalent_to!
    ]
  end  
  
  def blank!(ontology)
    matched_concepts[ontology].each_pair do |key, concepts|
      concepts.each{|concept| to_test << concept}
    end
  end
  
  def include_superclasses!(ontology)
    matched_concepts[ontology][:classes].each do |mc|
      owl_class_for_concept(mc, ontology).superclasses.collect{|c| c.class_url}.each{|sc| add_test!(sc)}
    end
  end
  
  def include_subclasses!(ontology)
    matched_concepts[ontology][:classes].each do |mc|
      owl_class_for_concept(mc, ontology).subclasses.collect{|c| c.class_url}.each{|sc| add_test!(sc)}
    end
  end
  
  def include_siblings!(ontology)
    matched_concepts[ontology][:classes].each do |mc|
      owl_class_for_concept(mc, ontology).all_siblings.each{|sc| add_test!(sc)}
    end
  end
  
  def go_really_deep!(ontology)
    matched_concepts[ontology][:classes].each do |mc|
      clazz = owl_class_for_concept(mc, ontology)
      base = clazz.subclasses.collect{|c| c.class_url} + clazz.superclasses.collect{|c| c.class_url} + clazz.all_siblings
      base.each{|b| to_test << b}
      additions = Set.new(clazz.all_superclasses + clazz.all_subclasses + clazz.all_siblings).to_a - base
      additions.each{|nc| add_test!(nc)}
    end
  end
  
  def owl_class_for_concept(concept_url, ontology)
    ontology.classes.find{|c| c.class_url == concept_url}
  end
  
  def build_range_patterns!(ontology)
    # all outgoing relations
    matched_concepts[ontology][:classes].each do |mc|
      add_test!(mc)
      ontology.outgoing_relations(mc).each do |rel_out|
        domains, ranges = ontology.relation_information(rel_out.url)
        domains.each{|domain| add_test!(domain)}
        add_test!(rel_out.url)
      end
    end
  end
  
  def build_domain_patterns!(ontology)
    # and all incoming ones
    matched_concepts[ontology][:classes].each do |mc| 
      add_test!(mc)
      ontology.incoming_relations(mc).each do |rel_in|
        domains, ranges = ontology.relation_information(rel_in.url)        
        add_test!(rel_in.url)
        ranges.each{|range| add_test!(range)}
      end
    end
  end
  
  def include_attributes!(ontology)
    matched_concepts[ontology][:classes].each do |mc|    
      ontology.attributes_of(mc).each do |attrib|
        add_test!(attrib)
      end
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
  
  def include_inverse_properties!(ontology)
    matched_concepts[ontology][:relations].each do |mr|
      ontology.inverse_concepts(mr).each do |inv_concept|
        add_test!(inv_concept)
      end
    end
  end
  
  def include_equivalent_to!(ontology)
    matched_concepts[ontology][:classes].each do |mc|
      ontology.equivalent_classes(mc).each do |equiv_concept|
        add_test!(equiv_concept)
      end
    end
    (matched_concepts[ontology][:attributes] + matched_concepts[ontology][:relations]).each do |mc|
      ontology.equivalent_properties(mc).each do |equiv_concept|
        add_test!(equiv_concept)
      end
    end
  end
  
  def include_subproperties!(ontology)
    matched_concepts[ontology][:relations].each do |mr|
      ontology.sub_properties_of(mr).each do |subprop|
        add_test!(subprop)
      end
    end
  end
  
  # determines the lookup key for each ontology
  def key_for_ontology(ontology)
    matcher.source_ontology == ontology ? :source : :target
  end
  
  def add_test!(concept)
    raise if concept.start_with?("_:")
    new_tests << concept #unless to_test.include?(concept)
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
      missing_correspondences.size.to_i,
      excess_correspondences.size.to_i,
      baseline_concepts(source_ontology).size.to_i,
      baseline_concepts(target_ontology).size.to_i,
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
      stats[:baseline] == 0 ? 0 : (stats[:interaction_expectancy].to_f / stats[:baseline].to_f).round(2),
      stats[:matches],
      stats[:removals]
    ].concat(alignment_stats)
  end
  
  def self.experiment_header
    return ["_L", "_R"].collect{|suf|
      [
        "#Found#{suf}",
        "Sample_Size",
        "Expectancy#{suf}",
        "Baseline",
        "Saving",
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
      "#Missing_Corr",
      "#False_Corr",
      "#BaselineConcepts_O1",
      "#BaselineConcepts_O2",      
      "Precision",
      "Recall",
      "F-Measure"
    ]
  end
end