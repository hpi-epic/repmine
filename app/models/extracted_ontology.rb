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
    if File.exist?(local_file_path)
      RDF::Graph.load(ont_file_path)
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
    return short_name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')
  end
  
  def file_format
    return repository.nil? ? "rdf" : repository.class.rdf_format
  end
  
  # returns an rdf file of the graph
  def rdf_xml
    if @rdf_graph.nil?
      raise "please either load or create the graph before generating rdf/xml!"
    end
    fix_seon_imports!
    buffer = RDF::RDFXML::Writer.buffer(:prefixes => prefixes) do |writer|
      writer.write_graph(@rdf_graph)
    end
    return buffer
  end
  
  private
  
  # this fixes some URL issues in the SEON ontologies. A more general fix would be to follow all owl:imports
  # and then check whether or not they are a valid URI...
  def fix_seon_imports!()
    seon_404 = "http://se-on.org/"
    seon_200 = "https://seal-team.ifi.uzh.ch/seon/"
    to_insert = []
    to_remove = []
    q = RDF::Query.new{pattern([:ont, RDF::OWL.imports, :imported_ont])}
    @rdf_graph.query(q).each do |res|
      if res[:imported_ont].to_s.starts_with?(seon_404)
        to_remove << [res[:ont], RDF::OWL.imports, res[:imported_ont]]
        to_insert << [res[:ont], RDF::OWL.imports, RDF::Resource.new(res[:imported_ont].to_s.gsub(seon_404, seon_200))]
      end
    end
    @rdf_graph.delete(*to_remove)
    @rdf_graph.insert(*to_insert)
  end
end