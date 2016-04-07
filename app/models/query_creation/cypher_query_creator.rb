class CypherQueryCreator < QueryCreator

  DIFFERING_OPERATORS = {
    AttributeConstraint::OPERATORS[:not] => "<>"
  }

  def build_query
    "MATCH #{match} #{parameters} RETURN #{return_values}".strip.gsub(/\s\s+/, ' ')
  end

  def match
    pattern.nodes.collect{|pn| paths_for_node(pn)}.flatten.compact.join(", ")
  end

  def paths_for_node(node)
    # only "isolated" nodes need to be added as-is, the rest will be added through incoming relations, eventually
    if node.source_relation_constraints.empty? && node.target_relation_constraints.empty?
      return [node_reference(node)]
    else
      return node.source_relation_constraints.collect do |rc|
        "#{node_reference(node)}-#{relation_reference(rc)}->#{node_reference(rc.target)}"
      end
    end
  end

  def node_reference(node)
    "(#{pe_variable(node)}:`#{node.label_for_type}`)"
  end

  def relation_reference(rel)
    "[#{pe_variable(rel)}:`#{rel.label_for_type}`]"
  end

  def attribute_reference(ac)
    "#{pe_variable(ac.node)}.#{ac.label_for_type}"
  end

  def return_values
    pattern.returnable_elements(aggregations).collect{|pe| return_variable(pe)}.join(", ")
  end

  def parameters
    str = pattern.attribute_constraints(monitoring_task_id).collect do |ac|
      unless ac.operator == AttributeConstraint::OPERATORS[:var]
        if ac.operator == AttributeConstraint::OPERATORS[:not] && ac.value.blank?
          "has(#{attribute_reference(ac)})"
        else
          "#{attribute_reference(ac)} #{cypher_operator(ac.operator)} #{escaped_value(ac)}"
        end
      end
    end.compact.join(" AND ")
    return str.empty? ? "" : "WHERE #{str}"
  end

  # for a given pattern element, we have to say how it is returned. This needs to ba vastly simplified...
  def return_variable(pe)
    unless aggregation_for_element(pe).nil?
      aggregated_variable(pe)
    else
      simple_variable(pe)
    end
  end

  def pe_variable(pe)
    pe.is_a?(AttributeConstraint) ? attribute_reference(pe) : super
  end

  def simple_variable(pe)
    pe.is_a?(Node) ? "id(#{pe_variable(pe)})" : pe_variable(pe)
  end

  def aggregated_variable(pe)
    agg = aggregation_for_element(pe)

    str = if agg.is_grouping?
      simple_variable(pe)
    else
      if agg.operation.nil?
        "#{distinct(agg)}#{pe_variable(pe)}"
      else
        "#{agg.operation.to_s}(#{distinct(agg)}#{pe_variable(pe)})"
      end
    end

    str + " AS #{agg.alias_name}"
  end

  def distinct(agg)
    agg.distinct ? "distinct " : ""
  end

  # we mainly use the sames ones as cypher...this is just in case, I forgot something...
  def cypher_operator(operator)
    return DIFFERING_OPERATORS[operator] || operator
  end

  def escaped_value(ac)
    if ac.refers_to_variable?
      return attribute_reference(ac.referenced_element)
    elsif ac.value_type == RDF::XSD.string
      return "'#{escape_str(clean_value(ac))}'"
    else
      return ac.value
    end
  end

  def clean_value(ac)
    if ac.operator == AttributeConstraint::OPERATORS[:regex]
      return "#{ac.value.scan(/^\/(.*)\//).flatten.first || ac.value}"
    else
      return ac.value
    end
  end

  def escape_str(str)
    str.is_a?(String) ? str.gsub("'", %q(\\\')) : str
  end

  def update_query(filters, target_values, ontology)
    query = "MATCH (n {" + filters.collect{|key,val| "#{ontology.label_for_resource(key)}:'#{escape_str(val)}'"}.join(", ")  + "}) "
    query += "SET " + target_values.collect{|key, val| "n.#{ontology.label_for_resource(key)} = '#{escape_str(val)}'"}.join(", ") + " "
    query + "RETURN id(n)"
  end
end