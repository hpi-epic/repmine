class OwlClass
  attr_accessor :subclasses, :name, :relations, :attributes, :schema, :class_url
  
  include RdfSerialization
  
  def initialize(schema, name, url = nil)
    @subclasses = Set.new
    @schema = schema
    @name = name
    @relations = Set.new
    @attributes = Set.new
    @class_url = url
    schema.add_class(self) unless schema.nil?
  end
  
  def add_attribute(name, range)
    a = Attribute.new(name, range, self)
    attributes << a
    return a
  end
  
  def add_relation(name, target_class)
    r = Relation.new(name, target_class, self)
    relations << r
    return r
  end
  
  def url
    return class_url || (schema.url + "/" + name)
  end
  
  def statements
    stmts = [
      [resource, RDF.type, RDF::OWL.Class],
      [resource, RDF::RDFS.isDefinedBy, RDF::Resource.new(schema.url)],
      [resource, RDF::RDFS.label, RDF::Literal.new(name)],
      [resource, RDF::RDFS.comment, RDF::Literal.new("Class generated by schema extractor.")]
    ]    
    return stmts
  end
  
  def schema_statements
    stmts = []
    relations.each{|rel| stmts.concat(rel.all_statements)}
    attributes.each{|att| stmts.concat(att.all_statements)}
    return stmts
  end
end