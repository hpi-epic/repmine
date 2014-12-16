class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port, :db_name, :db_username, :db_password
  has_one :ontology
  
  validates :name, :presence => true
  
  TYPES = ["MongoDbRepository", "RdfRepository", "RdbmsRepository"]
  
  # custom error class for ontology extraction
  class OntologyExtractionError < StandardError
  end
  
  after_create :build_ontology
  
  # overwrite this if you need a different format
  def self.rdf_format
    "ttl"
  end
  
  def self.default_port
    return nil
  end
  
  def self.for_type(type, params = {})
    if TYPES.include?(type)
      return class_eval(type).new(params)
    end
  end
  
  def editable_attributes
    return self.class.accessible_attributes.select{|at| !at.blank?}
  end
  
  def build_ontology
    self.ontology = ExtractedOntology.new(:short_name => self.name, :does_exist => false, :group => "Extracted")
    self.save
  end

  def extract_ontology!
    create_ontology!
    ontology.load_to_dedicated_repository!
    ontology.update_attributes({:does_exist => true})
  end
  
  def create_ontology!
    raise "implement #{create_ontology} for #{self.class.name} to create a RDFS+OWL ontology file for our repository"
  end
  
  def type_statistics
    raise "implement 'type_statistics' in #{self.class.name}"
  end
  
  def database_type
    "Generic"
  end
  
  def database_version
    return "1.0"
  end
  
  def query_creator(pattern)
    return self.class.query_creator_class.new(pattern, self)
  end
  
  def self.query_creator_class
    SparqlQueryCreator
  end
  
  def type_hierarchy
    return ontology.type_hierarchy
  end
  
  def imports
    return [Vocabularies::SchemaExtraction].concat(custom_imports)
  end
  
  # overwrite this if your repository needs custom information within the ontology
  def custom_imports
    return []
  end
  
  def self.all_that_have_an_ontology
    self.all.select{|repo| repo.ontology.does_exist}
  end
end