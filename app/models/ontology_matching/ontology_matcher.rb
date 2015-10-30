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

  def delete_alignment_repository!
    alignment_repo.delete!
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
    alignment_repo.repository.insert(Vocabularies::GraphPattern.to_enum)
    alignment_repo.insert_file!(alignment_path) if File.exist?(alignment_path)
    deanonymize_correspondences!
  end

  def deanonymize_correspondences!
    alignment_graph.query(all_correspondence_query) do |r|
      next unless r[:cell].anonymous?
      alignment_graph.delete([r[:cell]])
      sc = SimpleCorrespondence.new(measure: r[:measure].to_f, relation: r[:relation].to_s)
      sc.onto1 = source_ontology
      sc.onto2 = target_ontology
      sc.entity1 = r[:e1].to_s
      sc.entity2 = r[:e2].to_s
      sc.save
    end
  end

  def call_matcher!
    cmd = "java -jar AgreementMakerLightCLI.jar -m -s #{source_ontology.local_file_path} -t #{target_ontology.local_file_path} -o #{alignment_path}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml-jar")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
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

  def all_correspondence_query
    patterns = [
      [:cell, Vocabularies::Alignment.entity1, :e1],
      [:cell, Vocabularies::Alignment.entity2, :e2],
      [:cell, Vocabularies::Alignment.relation, :relation],
      [:cell, Vocabularies::Alignment.measure, :measure]
    ]
    return RDF::Query.new(*patterns.collect{|pat| RDF::Query::Pattern.new(*pat)})
  end

  def simple_correspondence_query(concept)
    e1, e2 = entities_in_order()
    patterns = [
      [:cell, e1, RDF::Resource.new(concept)],
      [:cell, e2, :target],
      [:cell, Vocabularies::Alignment.relation, :relation],
      [:cell, Vocabularies::Alignment.measure, :measure],
      [:cell, Vocabularies::Alignment.db_id, :db_id]
    ]
    return RDF::Query.new(*patterns.collect{|pat| RDF::Query::Pattern.new(*pat)})
  end

  def complex_correspondence_query(pattern_elements)
    e1,e2 = entities_in_order

    patterns = [
      [:cell, e1, :pattern],
      [:cell, e2, :target],
      [:cell, Vocabularies::Alignment.relation, :relation],
      [:cell, Vocabularies::Alignment.measure, :measure],
      [:cell, Vocabularies::Alignment.db_id, :db_id]
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
    correspondence = Correspondence.find(result[:db_id].to_i)
    correspondence.entity1 = entity1
    correspondence.entity2 = if result[:target].anonymous?
      Pattern.from_graph(alignment_graph, result[:target], target_ontology)
    else
      result[:target].to_s
    end
    return correspondence
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
    find_all_subnodes_of(c_node).each{|sn| alignment_graph.delete([sn])}
    alignment_graph.delete([c_node])
  end

  def find_all_subnodes_of(c_node)
    subnodes = []
    alignment_graph.build_query do |q|
      q.pattern [:sn, Vocabularies::Alignment.part_of, c_node]
    end.run do |res|
      subnodes << res[:sn]
    end
    return subnodes
  end

  def find_correspondence_node(correspondence)
    alignment_graph.query(RDF::Query.new(*correspondence.query_patterns)) do |res|
      return res[:cell]
    end
    return nil
  end
end