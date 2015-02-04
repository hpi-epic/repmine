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
      alignment_repo.insert_file!(alignment_path)
    end
  end
  
  def prepare_matching!
    target_ontology.download!
    source_ontology.download!
  end
  
  def already_matched?()
    !alignment_graph.empty?
  end
  
  def reset!()
    call_matcher!
    alignment_repo.clear!
    alignment_repo.insert_file!(alignment_path)
  end

  def call_matcher!
    cmd = "java -jar AgreementMakerLightCLI.jar -m -s #{source_ontology.local_file_path} -t #{target_ontology.local_file_path} -o #{alignment_path}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml-jar")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
      raise MatchingError, errors unless errors.blank?
    end
    clean_uris!(alignment_path)
  end
  
  def alignment_path()
    fn = "ont_#{source_ontology.id}_ont_#{target_ontology.id}.rdf"
    Rails.root.join("public", "ontologies", "alignments", fn).to_s
  end

  # gets correspondences for a single ontology element (class, attribute, relation)
  # if called with nil as a concept, all correspondences will be returned
  def correspondences_for_concept(concept)
    correspondences = []
    alignment_graph.query(correspondence_query(concept)) do |result|
      correspondences << create_correspondence(result)
    end
    return correspondences
  end
  
  # return correspondences for a given pattern
  def correspondences_for_pattern(pattern)

  end
  
  def all_correspondences()
    correspondences_for_concept(nil)
  end
  
  def correspondence_query(concept)
    concept_resource = concept.nil? ? :source : RDF::Resource.new(concept)
    patterns = [
      [:cell, Vocabularies::Alignment.entity1, inverted ? :target : concept_resource],
      [:cell, Vocabularies::Alignment.entity2, inverted ? concept_resource : :target],
      [:cell, inverted ? Vocabularies::Alignment.entity2 : Vocabularies::Alignment.entity1, :source],
      [:cell, Vocabularies::Alignment.relation, :relation],
      [:cell, Vocabularies::Alignment.measure, :measure]
    ]
    return RDF::Query.new(*patterns.collect{|pat| RDF::Query::Pattern.new(*pat)})
  end
  
  def create_correspondence(result)
    if result[:target].anonymous?
      create_complex_correspondence(result)
    else
      create_simple_correspondence(result)
    end
  end
  
  def create_simple_correspondence(result)
    return SimpleCorrespondence.new(
      result[:measure].to_f,
      result[:relation].to_s,
      result[:source].to_s,
      result[:target].to_s,
      source_ontology,
      target_ontology
    )
  end
  
  def alignment_graph
    alignment_repo.repository
  end
  
  def clean_uris!(path)
    g = RDF::Graph.load(path)
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.onto1, :onto1])
      pattern([:alignment, Vocabularies::Alignment.onto2, :onto2])
    }
    g.query(q) do |res|
      rdfxml = File.open(path).read
      rdfxml.gsub!(res[:onto1].to_s, res[:onto1].to_s + "/") unless res[:onto1].to_s.ends_with?("/")
      rdfxml.gsub!(res[:onto2].to_s, res[:onto2].to_s + "/") unless res[:onto2].to_s.ends_with?("/")
      File.open(path, "wb"){|f| f.puts rdfxml}
    end
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