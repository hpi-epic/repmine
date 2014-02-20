require 'vocabularies/schema_extraction.rb'

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
    # we describe an ontology
    graph << [resource, RDF.type, RDF::OWL.Ontology]
    repository.imports.each{|vocab| graph << [resource, RDF::OWL.imports, vocab]}
    graph << [resource, RDF::DC.title, repository.name]
    graph << [resource, RDF::DC.creator, RDF::Literal.new("Repmine Schema Extractor")]
    graph << [resource, RDF::SchemaExtraction.repositoryDatabase, RDF::Literal.new(repository.database_type)]
    graph << [resource, RDF::SchemaExtraction.repositoryDatabaseVersion, RDF::Literal.new(repository.database_version)] 
    # it contains the classes themselves
    classes.each{|klazz| graph.insert(*klazz.all_statements)}
    # then, their attributes and relations. This should prevent inline classes
    classes.each{|klazz| graph.insert(*klazz.schema_statements)}    
    return graph
  end
  
  # returns an rdf xml file of the graph. maybe we could change this in the future to use other writers, as well...
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
     :schema_extraction => RDF::SchemaExtraction,
     uri.split("/").last.underscore => uri
    }
  end
end
