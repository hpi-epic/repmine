require 'open3'

class OntologyMatcher

  attr_accessor :target_ontology, :source_ontology, :alignment_repo, :inverted

  class MatchingError < StandardError;end

  def initialize(source_ontology, target_ontology)
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
    insert_graph_pattern_ontology!
    alignment_repo.insert_file!(alignment_path) if File.exist?(alignment_path)
    deanonymize_correspondences!
  end

  def insert_graph_pattern_ontology!
    alignment_repo.repository.insert(Vocabularies::GraphPattern.to_enum)
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
    cmd = "java -jar AgreementMakerLight.jar -m -s #{source_ontology.local_file_path} -t #{target_ontology.local_file_path} -o #{alignment_path}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml-jar")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
      puts errors unless errors.blank?
    end
  end

  def alignment_path()
    fn = "ont_#{source_ontology.id}_ont_#{target_ontology.id}.rdf"
    Rails.root.join("public", "ontologies", "alignments", fn).to_s
  end

  # gets correspondences for a single ontology element (class, attribute, relation)
  # if called with nil as a concept, all correspondences will be returned
  def correspondences_for(elements)
    corr_map = Correspondence.candidates_for(source_ontology, target_ontology, elements, inverted)
    corr_map.each do |elements, correspondences|
      correspondences.each do |correspondence|
        correspondence.pattern_elements = build_target_graph(correspondence)
        correspondence.entity1 = elements
      end
    end
    return corr_map
  end

  def build_target_graph(correspondence)
    e1 = inverted ? Vocabularies::Alignment.entity2 : Vocabularies::Alignment.entity1
    e2 = inverted ? Vocabularies::Alignment.entity1 : Vocabularies::Alignment.entity2
    query_pattern = [[correspondence.resource, e1, :entity1], [correspondence.resource, e2, :entity2]]
    query = RDF::Query.new(*query_pattern.collect{|pat| RDF::Query::Pattern.new(*pat)})

    alignment_graph.query(query) do |result|
      if result[:entity2].anonymous?
        return Pattern.from_graph(alignment_graph, result[:entity2], target_ontology).pattern_elements
      else
        element = target_ontology.element_class_for_rdf_type(result[:entity2].to_s).new(:ontology_id => target_ontology.id)
        element.rdf_type = result[:entity2].to_s
        return [element]
      end
    end
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
    find_all_subnodes_of(correspondence.resource).each{|sn| alignment_graph.delete([sn])}
    alignment_graph.delete([correspondence.resource])
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

  def has_correspondence_node?(correspondence)
    alignment_graph.has_statement?(RDF::Statement.new(correspondence.resource, RDF.type, Vocabularies::Alignment.Cell))
  end
end