require 'open3'

class OntologyMatcher
  
  attr_accessor :ag_connection, :target_ontology, :source_ontology, :alignment_graph
  
  class MatchingError < StandardError;end
  
  def initialize(source_ontology, target_ontology)
    @source_ontology = source_ontology
    @target_ontology = target_ontology
    @alignment_graph = RDF::Graph.new()
  end
  
  def match!()
    prepare_matching!
    call_matcher! unless already_matched?
    add_to_alignment_graph!(alignment_path)
  end
  
  def alignment_graph
    add_to_alignment_graph!(alignment_path) if @alignment_graph.empty?
    return @alignment_graph
  end
  
  def add_to_alignment_graph!(path)
    @alignment_graph.load!(path) if File.exists?(path)
  end
  
  def write_alignment_graph!(output_path)
    RDF::Writer.open(output_path, :prefixes => {:alignment => Vocabularies::Alignment.to_s}) { |writer| writer << alignment_graph }
  end
  
  def add_correspondence!(correspondence)
    if correspondence.alignment.nil?
      q = RDF::Query.new{
        pattern([:alignment, RDF.type, Vocabularies::Alignment.Alignment])
      }
      alignment_graph.query(q).each do |res|
        correspondence.alignment = res[:alignment]
      end
    end
    alignment_graph.insert!(*correspondence.rdf)
    write_alignment_graph!(alignment_path)
  end
  
  def reset!
    @alignment_graph = RDF::Graph.new()
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
      File.open(path, "w+"){|f| f.puts rdfxml}
    end
  end
  
  def already_matched?
    return File.exist?(alignment_path)
  end
  
  # this is where the magic happens. We search the alignment graph for matches regarding the provided pattern element
  # TODO: widen the search to combinations, e.g., node -> relation -> node, etc.
  def get_substitutes_for(pattern_elements)
    correspondences = []
    pattern_elements.each do |pattern_element|
      # if we already have a correspondence -> no need to query the alignment graph
      existing_correspondences = pattern_element.ontology_correspondences.where(:output_ontology_id => target_ontology)
      unless existing_correspondences.empty?
        correspondences << existing_correspondences.first
        next
      end
      
      # otherwhise create the query patterns
      q = RDF::Query.new{
        pattern([:alignment, Vocabularies::Alignment.map, :cell])
        pattern([:cell, Vocabularies::Alignment.entity1, RDF::Resource.new(pattern_element.rdf_type)])
        pattern([:cell, Vocabularies::Alignment.entity2, :target])
        pattern([:cell, Vocabularies::Alignment.relation, :relation])
        pattern([:cell, Vocabularies::Alignment.measure, :measure])
      }
    
      # and issue them on the graph. TODO: check how complex correspondences are stored
      @alignment_graph.query(q) do |res|
        oc = OntologyCorrespondence.create(:input_ontology => source_ontology, :output_ontology => target_ontology, :measure => res[:measure].to_s, :relation => res[:relation].to_s)
        # add the input elements
        oc.input_elements << pattern_element
        # and the output_elements
        oc.output_elements << target_ontology.element_class_for_rdf_type(res[:target].to_s).for_rdf_type(res[:target].to_s)
        correspondences << oc
      end
    end
    return correspondences
  end
  
  def prepare_matching!
    target_ontology.download!
    target_ontology.load_to_dedicated_repository!
    source_ontology.download!    
  end
  
  def alignment_path()
    return Rails.root.join("public", "ontologies", "alignments", "ont_#{source_ontology.id}_ont_#{target_ontology.id}.rdf").to_s
  end

end