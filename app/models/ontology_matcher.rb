require 'open3'

class OntologyMatcher
  
  attr_accessor :ag_connection, :target_ontologies, :pattern, :alignment_graph
  
  class MatchingError < StandardError;end
  
  def initialize(pattern, target_ontologies)
    @pattern = pattern
    @target_ontologies = target_ontologies
    @alignment_graph = RDF::Graph.new()
  end
  
  def match!()
    prepare_matching!
    target_ontologies.each do |t_ont|
      pattern.ontologies.each do |s_ont|
        call_matcher!(s_ont, t_ont) unless already_matched?(s_ont, t_ont)
        add_to_alignment_graph!(alignment_path(s_ont, t_ont))
      end
    end
  end
  
  def add_to_alignment_graph!(path)
    alignment_graph.load!(path)
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
  
  # this is where the magic happens. We search the alignment graph for matches regarding the provided element
  def get_substitutes_for(element)
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.entity1, RDF::Resource.new(element)])
      pattern([:alignment, Vocabularies::Alignment.entity2, :target])
      pattern([:alignment, Vocabularies::Alignment.relation, :relation])
      pattern([:alignment, Vocabularies::Alignment.measure, :measure])
    }
    
    subs = []
    @alignment_graph.query(q) do |res|
      subs << {:entity2 => res[:target].to_s, :relation => res[:relation].to_s, :measure => res[:measure].to_s, :entity1 => element}
    end

    return subs
  end
  
  def prepare_matching!
    target_ontologies.each{|t| t.download!}
    pattern.ontologies.each{|p| p.download!}
  end
  
  def alignment_path(s_ont, t_ont)
    return Rails.root.join("public", "ontologies", "alignments", "ont_#{s_ont.id}_ont_#{t_ont.id}.rdf").to_s
  end

end