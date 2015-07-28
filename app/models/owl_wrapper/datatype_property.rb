class DatatypeProperty
  # domain is an owl_class object, range an RDF::Resource
  attr_accessor :name, :range, :domain, :attribute_url

  include RdfSerialization

  def initialize(name, range, domain)
    @name = name
    @range = range.is_a?(RDF::Resource) ? range : RDF::Resource.new(range)
    @domain = domain
  end

  def self.from_sample(name, domain, sample)
    return self.new(name, RDF::Literal.new(sample).datatype, domain)
  end

  def self.from_url(url, range, domain)
    name = url.split("/").last.split("#").last
    prop = self.new(name, range, domain)
    prop.attribute_url = url
    return prop
  end

  def url
    return attribute_url || domain.url + "/" + name
  end

  def rdf_statements
    stmts = [
      [resource, RDF.type, RDF::OWL.DatatypeProperty],
      [resource, RDF::RDFS.domain, domain.resource],
      [resource, RDF::RDFS.range, range],
      [resource, RDF::RDFS.label, RDF::Literal.new(name)]
    ]
  end

  def ==(other_object)
    return self.url == other_object.url
  end
end