class Attribute
  # domain is an owl_class object, range an RDF::Resource
  attr_accessor :name, :range, :domain, :attribute_url
  
  include RdfSerialization  
  
  def initialize(name, range, domain)
    @name = name
    @range = range.is_a?(RDF::Resource) ? range : RDF::Resource.new(range)
    @domain = domain
  end
  
  def self.from_url(url, range, domain)
    name = url.gsub(domain.url.to_s + "/", "").split("#").last
    attrib = self.new(name, range, domain)
    attrib.attribute_url = url
    return attrib
  end
  
  def url
    return attribute_url || domain.url + "/" + name
  end
  
  def rdf_statements
    stmts = [
      [resource, RDF.type, RDF::OWL.DatatypeProperty],
      [resource, RDF::RDFS.domain, domain.resource],
      [resource, RDF::RDFS.range, range]
    ]
  end
end
