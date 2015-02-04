require 'open3'

class OntologyMatcher

  attr_accessor :target_ontology, :source_ontology, :alignment_repo

  class MatchingError < StandardError;end

  def initialize(source_ontology, target_ontology, use_speaking_names = false)
    @source_ontology = source_ontology
    @target_ontology = target_ontology
    @alignment_repo = AgraphConnection.new(repo_name)
  end
  
  def repo_name
    "alignment_" + [@source_ontology, @target_ontology].sort{|a,b| a.id <=> b.id}.collect{|o| o.id.to_s}.join("_")
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
  def correspondences_for_concept(concept, invert = false)
    correspondences = []
    alignment_graph.query(correspondence_query(concept, invert)) do |res|
      correspondences << SimpleCorrespondence.new(
        res[:measure].to_f,
        res[:relation].to_s,
        concept,
        res[:target].to_s,
        invert ? target_ontology : source_ontology,
        invert ? source_ontology : target_ontology
      )
    end
    return correspondences
  end
  
  def correspondences_for_pattern(pattern)
    
  end
  
  def correspondence_query(concept, invert)
    return RDF::Query.new{
      pattern([:cell, Vocabularies::Alignment.entity1, invert ? :target : RDF::Resource.new(concept)])
      pattern([:cell, Vocabularies::Alignment.entity2, invert ? RDF::Resource.new(concept) : :target])
      pattern([:cell, Vocabularies::Alignment.relation, :relation])
      pattern([:cell, Vocabularies::Alignment.measure, :measure])
    }
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
    q = RDF::Query.new()
    correspondence.query_patterns.each{|qp| q << qp}
    alignment_graph.query(q) do |res|
      return res[:cell]
    end
    return nil
  end
end