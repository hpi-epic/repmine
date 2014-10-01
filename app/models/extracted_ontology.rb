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
  
  def custom_rdf_statements
    # we describe an ontology
    stmts = []
    repository.imports.each{|vocab| stmts << [resource, RDF::OWL.imports, vocab]}
    stmts << [resource, RDF::DC.title, repository.name]
    stmts << [resource, RDF::DC.creator, RDF::Literal.new("Repmine Schema Extractor")]
    stmts << [resource, Vocabularies::SchemaExtraction.repository_database, RDF::Literal.new(repository.database_type)]
    stmts << [resource, Vocabularies::SchemaExtraction.repository_database_version, RDF::Literal.new(repository.database_version)] 
    
    # and simply get all statements for each class
    classes.each{|klazz| stmts.concat(klazz.rdf)}
    return stmts
  end
  
  def rdf_types
    [RDF::OWL.Ontology]
  end
  
  def load_ontology
    does_exist ? RDF::Graph.load(local_file_path) : nil
  end
  
  def custom_prefixes
    return {
     :schema_extraction => Vocabularies::SchemaExtraction,
     url.split("/").last.underscore => url
    }
  end
  
  def get_url
    return "ontologies/extracted/#{name_url_safe}.#{file_format}"
  end
  
  def ont_url
    return ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:extracted_ontologies_path] + name_url_safe
  end
  
  def local_file_path
    return Rails.root.join("public", "ontologies", "extracted", name_url_safe + ".#{file_format}")
  end
  
  def name_url_safe
    url_safe_name = short_name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')
    url_safe_name += "_#{repository.id}" unless repository.nil?  
    return url_safe_name
  end
  
  def file_format
    return repository.nil? ? "owl" : repository.class.rdf_format
  end
  
end