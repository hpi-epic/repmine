class Schema
  
  attr_accessor :classes, :uri, :repository
  include RdfSerialization  
  
  def initialize(repository)
    @classes = Set.new()
    @uri = repository.ont_url
    @repository = repository
  end
  
  def add_class(klazz)
    @classes << klazz
  end
  
  def graph
    graph = RDF::Graph.new()
    graph << [resource, RDF.type, RDF::OWL.Ontology]
    graph << [resource, RDF::DC.title, repository.name]
    classes.each{|klazz| graph.insert(*klazz.statements)}
    return graph
  end
  
  def rdf_xml
    buffer = RDF::RDFXML::Writer.buffer(:prefixes => self.xml_prefixes) do |writer|
      writer.write_graph(self.graph)
    end
    return buffer
  end
  
  def xml_prefixes
    return {
     :rdfs => RDF::RDFS,
     :owl => RDF::OWL,
     uri.split("/").last.underscore => uri
    }
  end
  
end
