require 'open3'

class OntologyMatcher
  
  attr_accessor :ag_connection, :target_ontology, :pattern, :alignment_graph
  
  class MatchingError < StandardError;end
  
  def initialize(pattern, target_ontology)
    @pattern = pattern
    @target_ontology = target_ontology
    @alignment_graph = RDF::Graph.new()
  end
  
  def match!()
    prepare_matching!
    pattern.ontologies.each do |s_ont|
      call_matcher!(s_ont, target_ontology) unless already_matched?(s_ont, target_ontology)
      add_to_alignment_graph!(alignment_path(s_ont, target_ontology))
    end
  end
  
  def alignment_graph
    match! if @alignment_graph.nil?
    return @alignment_graph
  end
  
  def add_to_alignment_graph!(path)
    alignment_graph.load!(path)
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
    write_alignment_graph!(alignment_path(correspondence.input_ontology, correspondence.output_ontology))
  end
  
  def reset!
    @alignment_graph = RDF::Graph.new()
  end
    
  def call_matcher!(s_ont, t_ont)
    cmd = "java -jar AgreementMakerLightCLI.jar -m -s #{s_ont.local_file_path} -t #{t_ont.local_file_path} -o #{alignment_path(s_ont, t_ont)}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml-jar")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
      raise MatchingError, errors unless errors.blank?
    end
    clean_uris!(alignment_path(s_ont, t_ont))
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
  
  def already_matched?(s_ont, t_ont)
    return File.exist?(alignment_path(s_ont, t_ont))
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
        pattern([:alignment, Vocabularies::Alignment.onto1, :onto1])
        pattern([:cell, Vocabularies::Alignment.entity1, RDF::Resource.new(pattern_element.rdf_type)])
        pattern([:cell, Vocabularies::Alignment.entity2, :target])
        pattern([:cell, Vocabularies::Alignment.relation, :relation])
        pattern([:cell, Vocabularies::Alignment.measure, :measure])
      }
    
      # and issue them on the graph
      @alignment_graph.query(q) do |res|
        o1 = Ontology.find_by_url(res[:onto1].to_s)
        oc = OntologyCorrespondence.create(
          :input_ontology => o1,
          :output_ontology => target_ontology, 
          :measure => res[:measure].to_s,
          :relation => res[:relation].to_s
        )
        # add the input elements
        oc.input_elements << pattern_element
        # and the output_elements -> TODO: complex correspondences
        oc.output_elements << pattern_element.class.for_rdf_type(res[:target].to_s)
        correspondences << oc
      end
    end
    return correspondences
  end
  
  def prepare_matching!
    target_ontology.download!
    pattern.ontologies.each{|p| p.download!}
  end
  
  def alignment_path(s_ont, t_ont)
    return Rails.root.join("public", "ontologies", "alignments", "ont_#{s_ont.id}_ont_#{t_ont.id}.rdf").to_s
  end

end