require 'vocabularies/schema_extraction.rb'
# TODO: unify this with ontology. This will also help vastly as it makes extracted schemas instantly available...

class ExtractedOntology < Ontology
  
  attr_accessor :classes
  belongs_to :repository

  include RdfSerialization  
  
  def add_class(klazz)
    classes << klazz
  end
  
  def classes
    @classes ||= Set.new()
    return @classes
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
     url.split("/").last.underscore => url
    }
  end
end
