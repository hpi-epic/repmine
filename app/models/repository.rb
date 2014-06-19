class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port, :db_name
  has_one :ontology, :dependent => :destroy
  
  TYPES = ["MongoDbRepository", "Neo4jRepository", "HanaGraphEngineRepository", "RdfRepository", "RdbmsRepository"]
  
  # custom error class for ontology extraction
  class OntologyExtractionError < StandardError
  end
  
  # hack because STI and associations suck when combined
  after_create :build_ontology
  
  # overwrite this if you need a different format
  def self.rdf_format
    "ttl"
  end
  
  def self.for_type(type, params = {})
    if TYPES.include?(type)
      return class_eval(type).new(params)
    end
  end
  
  def editable_attributes()
    return self.class.accessible_attributes.select{|at| !at.blank?}
  end
  
  def ont_file_path
    Rails.root.join("public", "ontologies", "extracted", friendly_name(name) + ".#{self.class.rdf_format}")
  end
  
  def ont_file_url
    "ontologies/extracted/#{friendly_name(name)}.#{self.class.rdf_format}"
  end
  
  def build_ontology
    self.ontology = ExtractedOntology.new(:url => ont_url)
    self.save
  end

  def extract_ontology!
    raise "implement #{extract_ontology} for #{self.class.name} to create a RDFS+OWL ontology file for our repository"
  end
  
  def get_type_stats()
    raise "implement 'get_type_stats' in #{self.class.name}"
  end
    
  # helpers ... helpers, everywhere
  def ont_url
    return ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:extracted_ontologies_path] + friendly_name(name)
  end
  
  def friendly_name(name)
    return name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')
  end
  
  def database_type
    "Generic"
  end
  
  def database_version
    return "1.0"
  end
  
  def imports
    return [RDF::SchemaExtraction].concat(custom_imports)
  end
  
  # overwrite this if your repository needs custom information within the ontology
  def custom_imports
    return []
  end
end