class ComplexCorrespondence < SimpleCorrespondence

  class UnsupportedCorrespondence < Exception;end

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
    elsif entity.is_a?(Array)
      element_statements = entity.collect{|element| element.rdf}.flatten(1)
      return self.class.clean_rdf_statements(element_statements, entity.first.pattern.resource)
    else
      return [RDF::Resource.new(entity), []]
    end
  end
  
  def self.clean_rdf_statements(stmts, resource)
    entity_cache = {resource => RDF::Node.new}
    stmts.each{|stmt| entity_cache[stmt[0]] ||= RDF::Node.new}
    anonymized_stmts = stmts.collect{|stmt| stmt.map!{|el| entity_cache[el] || el}}
    return [entity_cache[resource], anonymized_stmts]
  end
  
  def pattern_elements
    entity2.is_a?(Pattern) ? entity2.pattern_elements : super
  end
  
  def self.from_elements(input_elements, output_elements)
    if input_elements.size == 1 && output_elements.size == 1
      i_el = input_elements.first
      o_el = output_elements.first
      return SimpleCorrespondence.new(1.0, "=", i_el.rdf_type, o_el.rdf_type, i_el.ontology, o_el.ontology)
    else
      i_ont = input_elements.first.ontology
      o_ont = output_elements.first.ontology
      if !input_elements.all?{|el| el.ontology == i_ont} && !output_elements.collect{|el| el.ontology == o_ont}
        raise UnsupportedCorrespondence.new("All elements need to stem from the same ontology!")
      else
        return ComplexCorrespondence.new(1.0, "=", input_elements, output_elements, i_ont, o_ont)
      end
    end
  end
end
