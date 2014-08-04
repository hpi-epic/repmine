require 'vocabularies/schema_extraction.rb'

class ExtractedOntology < Ontology
  
  attr_accessor :classes
  belongs_to :repository

  include RdfSerialization  
  
  def self.model_name
    return Ontology.model_name
  end
  
  def add_class(klazz)
    classes << klazz
  end
  
  def classes
    @classes ||= Set.new()
    return @classes
  end
  
  def clear!
    @classes = Set.new()
  end
  
  def create_graph!
    @rdf_graph = RDF::Graph.new()
    # we describe an ontology
    @rdf_graph << [resource, RDF.type, RDF::OWL.Ontology]
    repository.imports.each{|vocab| @rdf_graph << [resource, RDF::OWL.imports, vocab]}
    @rdf_graph << [resource, RDF::DC.title, repository.name]
    @rdf_graph << [resource, RDF::DC.creator, RDF::Literal.new("Repmine Schema Extractor")]
    @rdf_graph << [resource, Vocabularies::SchemaExtraction.repository_database, RDF::Literal.new(repository.database_type)]
    @rdf_graph << [resource, Vocabularies::SchemaExtraction.repository_database_version, RDF::Literal.new(repository.database_version)] 
    # it contains the classes themselves
    classes.each{|klazz| @rdf_graph.insert(*klazz.all_statements)}
    # then, their attributes and relations. This should prevent inline classes
    classes.each{|klazz| @rdf_graph.insert(*klazz.schema_statements)}    
  end
  
  def load_ontology
    if File.exist?(repository.ont_file_path)
      RDF::Graph.load(repository.ont_file_path) 
    else
      nil
    end
  end
  
  def prefixes
    return {
     :rdfs => RDF::RDFS,
     :owl => RDF::OWL,
     :schema_extraction => Vocabularies::SchemaExtraction,
     url.split("/").last.underscore => url
    }
  end
  
  def filename
    return repository.ont_file_url
  end
  
  def local_path
    return repository.ont_file_path
  end
  
  def download!
    return true
  end
  
  # returns an rdf file of the graph
  def rdf_xml
    if @rdf_graph.nil?
      raise "please either load or create the graph before generating rdf/xml!"
    end
    
    buffer = RDF::RDFXML::Writer.buffer(:prefixes => prefixes) do |writer|
      writer.write_graph(@rdf_graph)
    end
    return buffer
  end
end