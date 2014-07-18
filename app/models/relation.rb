class Relation
  attr_accessor :domain, :range, :name, :relation_url
  
  include RdfSerialization
    
  def initialize(name, range, domain)
    @domain = domain
    @range = range
    @name = name
  end  
  
  def self.from_url(url, range, domain)
    name = url.split("/").last.split("#").last
    relation = self.new(name, range, domain)
    relation.relation_url = url
    return relation
  end
  
  def url
    return relation_url || (domain.url + "/" + name)
  end
  
  def statements
    stmts = [
      [resource, RDF.type, RDF::OWL.ObjectProperty],
      [resource, RDF.domain, domain.resource],
      [resource, RDF.range, range.resource]
    ]
  end
end
