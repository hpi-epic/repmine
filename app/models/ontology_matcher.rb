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
    cmd = "java -jar aml.jar -m -s #{source_ont.local_file_path} -t #{target_ont.local_file_path} -o #{alignment_path}"
    errors = nil
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml")) do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
      if errors.blank? 
        build_alignment_graph! 
      else
        raise MatchingError, errors
      end
    end
  end
  
  def build_alignment_graph!()
    @alignment_graph = RDF::Graph.load(alignment_path)
  end
  
  # this is where the magic will happen
  def get_substitutes_for(element)
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.entity1, RDF::Resource.new(element)])
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
  
  def prepare_matching!
    target_ont.download!
    @source_ont = pattern.comprehensive_ontology
    @source_ont.download!
  end
  
  def alignment_path
    Rails.root.join("public", "ontologies", "alignments",  "#{source_ont.short_name}_#{target_ont.short_name}.rdf")
  end
  
end