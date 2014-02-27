class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port
  has_one :ontology
  
  after_create :build_ontology
  
  TYPES = ["MongoDbRepository", "Neo4jRepository", "HanaGraphEngineRepository"]
  
  def self.for_type(type, params = {})
    if TYPES.include?(type)
      return class_eval(type).new(params)
    end
  end
  
  def editable_attributes()
    return self.class.accessible_attributes.select{|at| !at.blank?}
  end
  
  def build_ontology
    o = ExtractedOntology.new(:url => self.ont_url)
    o.repository = self
    o.save
  end
  
  def extract_ontology(schema)
    raise "implement this in the subclasses"
  end
  
  # fancy statistics  
  def get_type_stats()
    raise "implement this in the subclasses"
  end
    
  # helpers ... helpers, everywhere
  def ont_url
    return ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:extracted_ontologies_path] + self.name
  end
  
  def database_type
    "Generic"
  end
  
  def database_version
    # TODO: get this information from the database itself
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