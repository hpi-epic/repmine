class OntologyCorrespondence < Struct.new(:entity1, :entity2, :measure, :relation, :ontology1, :ontology2, :node, :alignment)
  include RdfSerialization
  
  def rdf_types
    []
  end
  
  # he, who must not be named...
  def resource
    @node ||= RDF::Node.new()
    return @node
  end
  
  def rdf_statements
    cell = RDF::Node.new
    [
      [alignment, Vocabularies::Alignment.map, resource],
      [resource, RDF.type, Vocabularies::Alignment.Cell],
      [resource, Vocabularies::Alignment.entity1, RDF::Resource.new(entity1)],
      [resource, Vocabularies::Alignment.entity2, RDF::Resource.new(entity2)],
      [resource, Vocabularies::Alignment.measure, measure],
      [resource, Vocabularies::Alignment.relation, relation]
    ]
  end
end