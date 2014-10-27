require 'open3'

class OntologyMatcher
  
  attr_accessor :ag_connection, :source_ont, :target_ont, :pattern, :alignment_graph
  
  class MatchingError < StandardError;end
  
  def initialize(pattern, ont_t)
    @pattern = pattern
    @target_ont = ont_t
  end
  
  def match!()
    prepare_matching!  
    call_matcher! unless already_matched?
    build_alignment_graph!    
  end
  
  def call_matcher!
    cmd = "java -jar AgreementMakerLightCLI.jar -m -s #{source_ont.local_file_path} -t #{target_ont.local_file_path} -o #{alignment_path}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml-jar")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
      raise MatchingError, errors unless errors.blank?
    end
  end
  
  def build_alignment_graph!()
    @alignment_graph = RDF::Graph.load(alignment_path)
  end
  
  def already_matched?
    return File.exist?(alignment_path)
  end
  
  # this is where the magic will happen
  def get_substitutes_for(element)
    fixed_element = RDF::Resource.new(fix_ontology_namespaces(element))
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.entity1, fixed_element])
      pattern([:alignment, Vocabularies::Alignment.entity2, :target])
      pattern([:alignment, Vocabularies::Alignment.relation, :relation])
      pattern([:alignment, Vocabularies::Alignment.measure, :measure])
    }
    
    subs = []
    @alignment_graph.query(q) do |res|
      subs << {:entity => res[:target].to_s, :relation => res[:relation].to_s, :measure => res[:measure].to_s}
    end
    return subs
  end
  
  def fix_ontology_namespaces(element)
    q = RDF::Query.new {pattern([:alignment, Vocabularies::Alignment.onto1, :onto1])}
    @alignment_graph.query(q) do |res|
      onto1 = res[:onto1].to_s
      # fixes the extra / that is inserted somewhere between rdf.load and ag_connection.load... 
      if !onto1.ends_with?("/") && element.starts_with?(onto1 + "/")
        return element.gsub(onto1 + "/", onto1)
      end
      # adds the onto namespace in case we query only with the element label
      unless element.starts_with?(onto1)
        return onto1 + element
      end
    end
    # fallback ... just return the element
    return element
  end
  
  def prepare_matching!
    target_ont.download!
    @source_ont = pattern.comprehensive_ontology
    @source_ont.download!
  end
  
  def alignment_path
    filename = unless @source_ont.new_record?
      "ont_#{source_ont.id}_ont_#{target_ont.id}.rdf"
    else 
      "pattern_#{pattern.id}_ont_#{target_ont.id}.rdf"
    end
    return Rails.root.join("public", "ontologies", "alignments",  filename).to_s
  end
  
end