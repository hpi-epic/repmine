class Relation
  attr_accessor :domain, :range, :name
  
  include RdfSerialization
    
  def initialize(name, range, domain)
    @domain = domain
    @range = range
    @name = name
  end  
  
  def uri
    return domain.uri + "/" + name
  end
  
  def statements
    stmts = [
      [resource, RDF.type, RDF::OWL.ObjectProperty],
      [resource, RDF.domain, domain.resource],
      [resource, RDF.range, range]
    ]
  end  
end
