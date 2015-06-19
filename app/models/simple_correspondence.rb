class SimpleCorrespondence < Struct.new(:measure, :relation, :entity1, :entity2, :onto1, :onto2)
  include RdfSerialization
  
  attr_accessor :node

  def rdf_types
    [Vocabularies::Alignment.Cell]
  end
  
  def resource
    @resource ||= RDF::Node.new
  end
  
  def rdf_statements
    [
      [resource, Vocabularies::Alignment.entity1, RDF::Resource.new(entity1)],
      [resource, Vocabularies::Alignment.entity2, RDF::Resource.new(entity2)],
      [resource, Vocabularies::Alignment.measure, RDF::Literal.new(measure.to_f)],
      [resource, Vocabularies::Alignment.relation, RDF::Literal.new(relation)]
    ]
  end
  
  # the measure is somewhat problematic here due to floats being transformed weirdly...
  # hence, we remove this statement from our query...entities and relation should suffice, though  
  def query_patterns
    self.rdf_statements.select{|rdfs| rdfs[1] != Vocabularies::Alignment.measure}.collect{|qp| 
      RDF::Query::Pattern.new(*qp.map!{|x| x == resource ? :cell : x })
    }
  end
  
  def pattern_elements
    pe = onto2.element_class_for_rdf_type(entity2).new(:ontology_id => onto2.id)
    pe.rdf_type = entity2
    return [pe]
  end
end
