class ComplexCorrespondence < SimpleCorrespondence

  def rdf_statements()
    res1, stmts1 = process_entity(entity1)
    res2, stmts2 = process_entity(entity2)
    [
      [resource, Vocabularies::Alignment.entity1, res1],
      [resource, Vocabularies::Alignment.entity2, res2],
      [resource, Vocabularies::Alignment.measure, RDF::Literal.new(measure.to_f)],
      [resource, Vocabularies::Alignment.relation, RDF::Literal.new(relation)]
    ].concat(stmts1).concat(stmts2)
  end
  
  def process_entity(entity)
    if entity.is_a?(Pattern)
      return self.class.clean_rdf_statements(entity.rdf, entity.resource)
    else
      return [RDF::Resource.new(entity), []]
    end
  end
  
  def self.clean_rdf_statements(stmts, resource)
    entity_cache = {}
    stmts.each do |stmt|
      entity_cache[stmt[0]] ||= RDF::Node.new
    end
    anonymized_stmts = stmts.collect{|stmt| stmt.map!{|el| entity_cache[el] || el}}
    return [entity_cache[resource], anonymized_stmts]
  end
  
end
