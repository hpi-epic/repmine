class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port
  TYPES = ["MongoDbRepository", "Neo4jRepository", "HanaGraphEngineRepository"]
  
  def self.for_type(type, params = {})
    if TYPES.include?(type)
      return class_eval(type).new(params)
    end
  end
  
  def extract_schema()
    raise "implement this in the subclasses"
  end
  
  def editable_attributes()
    return self.class.accessible_attributes.select{|at| !at.blank?}
  end
  
  def get_type_stats()
    raise "implement this in the subclasses"
  end    
    
end