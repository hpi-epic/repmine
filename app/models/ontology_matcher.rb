require 'open3'

class OntologyMatcher

  attr_accessor :target_ontology, :source_ontology, :alignment_repo, :inverted

  class MatchingError < StandardError;end

  def initialize(source_ontology, target_ontology, use_speaking_names = false)
    @source_ontology, @target_ontology = [source_ontology, target_ontology].sort{|a,b| a.id <=> b.id}
    @inverted = @source_ontology != source_ontology
    @alignment_repo = AgraphConnection.new(repo_name)
  end
  
  def repo_name
    "alignment_" + [source_ontology, target_ontology].collect{|o| o.id.to_s}.join("_")
  end

  def match!()
    prepare_matching!
    unless already_matched?
      call_matcher!
      insert_statements!
    end
  end
  
  def prepare_matching!
    target_ontology.download!
    source_ontology.download!
  end
  
  def already_matched?()
    !alignment_graph.empty?
  end
  
  def insert_statements!
    alignment_repo.insert_file!(alignment_path) if File.exist?(alignment_path)
    alignment_repo.repository.insert(Vocabularies::GraphPattern.to_enum)
  end

  def call_matcher!
    cmd = "java -jar AgreementMakerLightCLI.jar -m -s #{source_ontology.local_file_path} -t #{target_ontology.local_file_path} -o #{alignment_path}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml-jar")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
      raise MatchingError, errors unless errors.blank?
    end
  end
  
  def alignment_path()
    fn = "ont_#{source_ontology.id}_ont_#{target_ontology.id}.rdf"
    Rails.root.join("public", "ontologies", "alignments", fn).to_s
  end

  # gets correspondences for a single ontology element (class, attribute, relation)
  # if called with nil as a concept, all correspondences will be returned
  def correspondences_for_concept(concept)
    correspondences = []
    alignment_graph.query(simple_correspondence_query(concept)) do |result|
      correspondences << create_correspondence(result, concept)
    end
    return correspondences
  end
  
  # gets a bunch of pattern elements (=< the entire pattern) and returns correspondences for that
  # 1. create a query that looks for patterns as entity1, which contain all the given elements
  # 2. execute that query
  # 3. return the correspondence  
  def correspondences_for_pattern_elements(elements)
    correspondences = []
    alignment_graph.query(complex_correspondence_query(elements)) do |result|
      matching_pattern = Pattern.from_graph(alignment_graph, result[:pattern], target_ontology)      
      if matching_pattern.pattern_elements.select{|pe| elements.none?{|el| el.equal_to?(pe)}}.empty?
        correspondences << create_correspondence(result, elements)
      end
    end
    return correspondences
  end
  
  def simple_correspondence_query(concept)
    e1, e2 = entities_in_order()
    patterns = [
      [:cell, e1, RDF::Resource.new(concept)],
      [:cell, e2, :target],
      [:cell, Vocabularies::Alignment.relation, :relation],
      [:cell, Vocabularies::Alignment.measure, :measure]
    ]
    return RDF::Query.new(*patterns.collect{|pat| RDF::Query::Pattern.new(*pat)})
  end
  
  def complex_correspondence_query(pattern_elements)
    e1,e2 = entities_in_order
    
    patterns = [
      [:cell, e1, :pattern],
      [:cell, e2, :target],
      [:cell, Vocabularies::Alignment.relation, :relation],
      [:cell, Vocabularies::Alignment.measure, :measure]
    ]
    
    pattern_elements.each_with_index do |pe, i|
      qv = "pe#{i}".to_sym
      patterns << [qv, Vocabularies::GraphPattern.belongsTo, :pattern]
      patterns << [qv, Vocabularies::GraphPattern.elementType, pe.type_expression.resource]
    end
    
    return RDF::Query.new(*patterns.collect{|pat| RDF::Query::Pattern.new(*pat)})
  end
  
  def entities_in_order
    e1 = inverted ? Vocabularies::Alignment.entity2 : Vocabularies::Alignment.entity1
    e2 = inverted ? Vocabularies::Alignment.entity1 : Vocabularies::Alignment.entity2
    return [e1,e2]    
  end
  
  def create_correspondence(result, entity1)
    # anonymous target -> input maps to pattern
    # array as entity1 -> input was a list of pattern elements
    if result[:target].anonymous? || entity1.is_a?(Array)      
      create_complex_correspondence(result, entity1)
    else
      create_simple_correspondence(result, entity1)
    end
  end
  
  def create_complex_correspondence(result, entity1)
    return ComplexCorrespondence.new(
      result[:measure].to_f,
      result[:relation].to_s,
      entity1,
      result[:target].anonymous? ? Pattern.from_graph(alignment_graph, result[:target], target_ontology) : result[:target].to_s,
      source_ontology,
      target_ontology
    )
  end
  
  def create_simple_correspondence(result, entity1)
    return SimpleCorrespondence.new(
      result[:measure].to_f,
      result[:relation].to_s,
      entity1,
      result[:target].to_s,
      source_ontology,
      target_ontology
    )
  end
  
  def print_alignment_graph!(ignore_gp = true)
    puts "+++ current alignment graph +++"
    contains_gp_stuff = false
    alignment_graph.each_statement do |stmt|
      if stmt[0].to_s.start_with?(Vocabularies::GraphPattern.to_s)
        contains_gp_stuff = true
        puts "s: #{stmt[0]}, p: #{stmt[1]}, o: #{stmt[2]}" unless ignore_gp
      else
        puts "s: #{stmt[0]}, p: #{stmt[1]}, o: #{stmt[2]}"
      end
    end
  end
  
  def alignment_graph
    alignment_repo.repository
  end
  
  def add_correspondence!(correspondence)
    alignment_graph.insert(*correspondence.rdf)
  end
  
  def remove_correspondence!(correspondence)
    c_node = find_correspondence_node(correspondence)
    return if c_node.nil?
    alignment_graph.delete([c_node])
  end
  
  def find_correspondence_node(correspondence)
    alignment_graph.query(RDF::Query.new(*correspondence.query_patterns)) do |res|
      return res[:cell]
    end
    return nil
  end
end