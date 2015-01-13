class OwlClass
  attr_accessor :subclasses, :name, :relations, :attributes, :schema, :class_url, :superclasses

  SET_OPS = {:sub => "&sub;", :sup => "&sup;", :not => "&not;"}

  include RdfSerialization

  def initialize(schema, name, url = nil)
    @subclasses = Set.new
    @superclasses = Set.new    
    @schema = schema
    @name = name
    @relations = Set.new
    @attributes = Set.new
    @class_url = url
    schema.add_class(self) unless schema.nil?
  end
  
  def is_subclass_of?(concept_url)
    direct = superclasses.any?{|sc| sc.class_url == concept_url}
    return direct || superclasses.any?{|sc| sc.is_subclass_of?(concept_url)}
  end
  
  def is_superclass_of?(concept_url)
    direct = subclasses.any?{|sc| sc.class_url == concept_url}
    return direct || subclasses.any?{|sc| sc.is_superclass_of?(concept_url)}
  end
  
  def is_sister_class_of?(concept_url)
    superclasses.any?{|sc| sc.subclasses.any?{|ssc| ssc.class_url == concept_url}}
  end
  
  def has_class_relation_with?(concept_url)
    is_subclass_of?(concept_url) || is_superclass_of?(concept_url) || is_sister_class_of?(concept_url)
  end
  
  def all_siblings()
    return superclasses.collect{|sc| sc.subclasses.collect{|scc| scc.class_url}}.flatten
  end
  
  def all_superclasses
    return superclasses.collect{|sc| sc.class_url} + superclasses.collect{|sc| sc.all_superclasses}.flatten
  end
  
  def all_subclasses
    return subclasses.collect{|sc| sc.class_url} + subclasses.collect{|sc| sc.all_subclasses}.flatten
  end
  
  def add_subclass(owl_class)
    @subclasses << owl_class
    owl_class.superclasses << self
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

  def rdf_statements
    stmts = [
      [resource, RDF.type, RDF::OWL.Class],
      [resource, RDF::RDFS.isDefinedBy, RDF::Resource.new(schema.url)],
      [resource, RDF::RDFS.label, RDF::Literal.new(name)],
      [resource, RDF::RDFS.comment, RDF::Literal.new("Class generated by schema extractor.")]
    ]
    relations.each{|rel| stmts.concat(rel.rdf)}
    attributes.each{|att| stmts.concat(att.rdf)}
    return stmts
  end

  def ==(other_object)
    return self.url == other_object.url
  end
end
