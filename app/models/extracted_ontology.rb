require 'vocabularies/schema_extraction.rb'

class ExtractedOntology < Ontology

  include RdfSerialization

  def load_immediately?
    return false
  end

  def self.model_name
    return Ontology.model_name
  end

  def rdf_statements
    # we describe an ontology
    stmts = []
    repository.imports.each{|vocab| stmts << [resource, RDF::OWL.imports, vocab]}
    stmts << [resource, RDF::DC.title, self.short_name]
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

  def custom_prefixes
    return {
     :schema_extraction => Vocabularies::SchemaExtraction,
     url.split("/").last.underscore => url,
     :dc => RDF::DC.to_s
    }
  end

  def local_file_path
    return Rails.root.join("public", "ontologies", "extracted", short_name.squish.downcase.tr(" ","_") + ".#{file_format}").to_s
  end

  def file_format
    return repository.nil? ? "owl" : repository.class.rdf_format
  end
  
  def download_url
    return ["ontologies", "extracted", short_name.squish.downcase.tr(" ","_") + ".#{file_format}"].join("/")
  end

end
