class SimpleCorrespondence < Correspondence

  def rdf_statements
    [
      [resource, Vocabularies::Alignment.entity1, RDF::Resource.new(entity1)],
      [resource, Vocabularies::Alignment.entity2, RDF::Resource.new(entity2)],
      [resource, Vocabularies::Alignment.measure, RDF::Literal.new(measure.to_f)],
      [resource, Vocabularies::Alignment.relation, RDF::Literal.new(relation)],
      [resource, Vocabularies::Alignment.db_id, RDF::Literal.new(id)]
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
    @pattern_elements ||= onto2.element_class_for_rdf_type(entity2).new(:ontology_id => onto2.id)
    @pattern_elements.rdf_type = entity2
    return [@pattern_elements]
  end
end
