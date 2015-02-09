# == Schema Information
#
# Table name: ontologies
#
#  id          :integer          not null, primary key
#  url         :string(255)
#  description :text
#  short_name  :string(255)
#  group       :string(255)
#  does_exist  :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'vocabularies/schema_extraction.rb'

class ExtractedOntology < Ontology

  include RdfSerialization

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
     url.split("/").last.underscore => url
    }
  end

  def local_file_path
    return Rails.root.join("public", "ontologies", "extracted", short_name + ".#{file_format}")
  end

  def file_format
    return repository.nil? ? "owl" : repository.class.rdf_format
  end

end
