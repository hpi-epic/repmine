class OwlClass
  attr_accessor :subclasses, :name, :relations, :attributes, :ont_uri
  
  def initialize(ont_uri, name)
    @subclasses = Set.new
    @ont_uri = ont_uri
    @name = name
    @relations = Set.new
    @attributes = Set.new
  end
  
  def add_attribute(name, type)
    attributes << Attribute.new(name, type, ont_uri)
  end
  
  def add_relation(name, target_class)
    relations << Relation.new(name, target_class, ont_uri)
  end
  
  def uri
    return ont_uri + "/" + name
  end
  
end