class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port
  has_one :ontology
  
  after_create :build_ontology
  
  TYPES = ["MongoDbRepository", "Neo4jRepository", "HanaGraphEngineRepository", "RdfRepository"]
  
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
  
  def extract_ontology!()
    raise "implement this in the subclasses"
  end
  
  def extract_and_store_ontology!
    o = extract_ontology!
    File.open(ont_file_path, "w+"){|f| f.puts o.rdf_xml}
    return o
  end
  
  def ont_file_path
    Rails.root.join("public", "rdf-xml", "extracted", self.name + ".rdf")
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