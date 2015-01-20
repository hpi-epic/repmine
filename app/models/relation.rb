class Relation
  attr_accessor :domain, :range, :name, :relation_url

  include RdfSerialization

  def initialize(name, domain, range)
    @domain = domain
    @range = range
    @name = name
  end

  def self.from_url(url, domain, range)
    name = url.split("/").last.split("#").last
    relation = self.new(name, domain, range)
    relation.relation_url = url
    return relation
  end

  def url
    return relation_url || (domain.url + "/" + name)
  end

  def rdf_statements
    stmts = [
      [resource, RDF.type, RDF::OWL.ObjectProperty],
      [resource, RDF::RDFS.domain, domain.resource],
      [resource, RDF::RDFS.range, range.resource]
    ]
  end

  def ==(other_object)
    return self.url == other_object.url
  end
end
