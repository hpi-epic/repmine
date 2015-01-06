require 'open3'

class OntologyMatcher

  attr_accessor :target_ontology, :source_ontology, :alignment_graph, :alignment_path, :speaking_names

  class MatchingError < StandardError;end

  def initialize(source_ontology, target_ontology, use_speaking_names = false)
    @source_ontology = source_ontology
    @target_ontology = target_ontology
    @speaking_names = use_speaking_names
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

  def add_correspondence!(correspondence)
    doc = Nokogiri::XML(File.open(alignment_path)){|doc| doc.noblanks}
    invert = correspondence.input_elements.first.ontology == target_ontology
    map = correspondence.xml_node(doc, invert)
    doc.css("Alignment").first.add_child(map)
    File.open(alignment_path, "wb"){|f| f.puts doc.to_xml}
    reload!
    return invert ? correspondences.output_elements.first : correspondence.input_elements.first
  end
  
  def remove_correspondence!(correspondence)
    doc = Nokogiri::XML(File.open(alignment_path)){|doc| doc.noblanks}
    doc.css("Alignment map").each do |map|
      e1 = map.css("entity1").first["rdf:resource"]
      e2 = map.css("entity2").first["rdf:resource"]
      map.remove if (e1 == correspondence.entity1 && e2 == correspondence.entity2) || (e1 == correspondence.entity2 && e2 == correspondence.entity1)
    end
    File.open(alignment_path, "wb"){|f| f.puts doc.to_xml}
    reload!
    correspondence.destroy
  end
  
  def reload!
    reset!
    add_to_alignment_graph!(alignment_path)
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
      File.open(path, "wb"){|f| f.puts rdfxml}
    end
  end

  # checks whether an alignment is present for source_ont_target_ont, if not, the same for the other way around
  def already_matched?
    if File.exist?(alignment_path)
      return true
    else
      if File.exist?(alignment_path_for(target_ontology, source_ontology))
        @alignment_path = alignment_path_for(target_ontology, source_ontology)
        return true
      end
    end
    return false
  end

  # this is where the magic happens. We search the alignment graph for matches regarding the provided pattern element
  def get_substitutes_for(pattern_elements, use_existing = true)
    correspondences = []
    pattern_elements.each do |pattern_element|
      correspondences.concat(get_simple_correspondences(pattern_element, use_existing))
    end
    # TODO: perform searches using multiple elements at once, i.e., complex correspondences
    return correspondences
  end
    
  def get_simple_correspondences(pattern_element, use_existing = true)
    correspondences = []
    # source_ontology is either the one of the pattern element or our source...
    source_ont = pattern_element.ontology || source_ontology
    target_ont = pattern_element.ontology == target_ontology ? source_ontology : target_ontology
        
    # if we already have a correspondence -> no need to query the alignment graph
    if use_existing
      existing_correspondences = pattern_element.ontology_correspondences.where(:output_ontology_id => target_ont)
      return existing_correspondences unless existing_correspondences.empty?
    end

    alignment_graph.query(correspondence_query(pattern_element)) do |res|
      oc = OntologyCorrespondence.create(
        :input_ontology => source_ont, 
        :output_ontology => target_ont, 
        :measure => res[:measure].to_s, 
        :relation => res[:relation].to_s
      )
      # add the input and output elements
      oc.input_elements << pattern_element
      oc.output_elements << target_ont.element_class_for_rdf_type(res[:target].to_s).for_rdf_type(res[:target].to_s)
      correspondences << oc
    end
    return correspondences
  end
  
  def correspondence_query(pattern_element)
    invert = pattern_element.ontology == target_ontology
    return RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.map, :cell])
      pattern([:cell, Vocabularies::Alignment.entity1, invert ? :target : RDF::Resource.new(pattern_element.rdf_type)])
      pattern([:cell, Vocabularies::Alignment.entity2, invert ? RDF::Resource.new(pattern_element.rdf_type) : :target])
      pattern([:cell, Vocabularies::Alignment.relation, :relation])
      pattern([:cell, Vocabularies::Alignment.measure, :measure])
    }
  end
  
  def all_correspondences
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.map, :cell])
      pattern([:cell, Vocabularies::Alignment.entity1, :source])
      pattern([:cell, Vocabularies::Alignment.entity2, :target])
      pattern([:cell, Vocabularies::Alignment.relation, :relation])
    }
    correspondences = []
    alignment_graph.query(q) do |res|    
      correspondences << {:s => res[:source].to_s, :t => res[:target].to_s, :r => res[:relation].to_s}
    end
    return correspondences
  end

  def matched_concepts()
    matched_concepts = {:source_ontology => [], :target_ontology => [], :correspondence_count => 0}
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.map, :cell])
      pattern([:cell, Vocabularies::Alignment.entity1, :source])
      pattern([:cell, Vocabularies::Alignment.entity2, :target])
    }
    alignment_graph.query(q).each do |res|
      matched_concepts[:source_ontology] << res[:source].to_s
      matched_concepts[:target_ontology] << res[:target].to_s
      matched_concepts[:correspondence_count] += 1
    end
    return matched_concepts
  end

  def prepare_matching!
    target_ontology.download!
    target_ontology.load_to_dedicated_repository!
    source_ontology.download!
  end

  def alignment_path()
    @alignment_path ||= alignment_path_for(source_ontology, target_ontology)
  end

  def alignment_path_for(source_ont, target_ont)
    fn = if speaking_names
      "#{source_ont.very_short_name}-#{target_ont.very_short_name}.rdf"
    else
      "ont_#{source_ont.id}_ont_#{target_ont.id}.rdf"
    end
    Rails.root.join("public", "ontologies", "alignments", fn).to_s
  end
end
