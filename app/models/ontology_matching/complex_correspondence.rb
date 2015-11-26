class ComplexCorrespondence < SimpleCorrespondence

  def rdf_statements()
    res1, stmts1 = process_entity(entity1)
    res2, stmts2 = process_entity(entity2)
    [
      [resource, Vocabularies::Alignment.entity1, res1],
      [resource, Vocabularies::Alignment.entity2, res2],
      [resource, Vocabularies::Alignment.measure, RDF::Literal.new(measure.to_f)],
      [resource, Vocabularies::Alignment.relation, RDF::Literal.new(relation)],
      [resource, Vocabularies::Alignment.db_id, RDF::Literal.new(id)]
    ].concat(stmts1).concat(stmts2)
  end

  def process_entity(entity)
    if entity.is_a?(Array)
      element_statements = entity.collect{|element| element.rdf}.flatten(1)
      return clean_rdf_statements(element_statements, entity.first.pattern.resource)
    else
      return [RDF::Resource.new(entity), []]
    end
  end

  def clean_rdf_statements(stmts, res)
    entity_cache = {res => RDF::Node.new}
    stmts.each{|stmt| entity_cache[stmt[0]] ||= RDF::Node.new}
    anonymized_stmts = stmts.collect{|stmt| stmt.map!{|el| entity_cache[el] || el}}
    claims = entity_cache.values.collect{|anon| [anon, Vocabularies::Alignment.part_of, resource]}
    return [entity_cache[res], anonymized_stmts + claims]
  end

end
