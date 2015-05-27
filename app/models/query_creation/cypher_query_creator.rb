class CypherQueryCreator < QueryCreator
  
  def build_query!
    "MATCH #{match} #{parameters} RETURN #{return_values} #{modifiers}".strip.gsub(/\s\s+/, ' ')
  end
  
  def match
    pattern.nodes.collect do |pn|
      paths_for_node(pn)
    end.flatten.compact.join(", ")
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
    "[:`#{rel.label_for_type}`]"
  end
  
  def attribute_reference(ac)
    "#{pe_variable(ac.node)}.#{ac.label_for_type}"
  end
  
  def return_values
    pattern.nodes.collect{|node| pe_variable(node)}.join(", ")
  end
  
  def parameters
    str = pattern.attribute_constraints.collect do |ac|
      unless ac.operator == AttributeConstraint::OPERATORS[:var]
        "#{attribute_reference(ac)} #{cypher_operator(ac.operator)} #{escaped_value(ac)}"
      end
    end.compact.join(" AND ")
    return str.empty? ? "" : "WHERE #{str}"
  end
  
  # we mainly use the sames ones as cypher...
  def cypher_operator(our_operator)
    return our_operator
  end
  
  def escaped_value(ac)
    if ac.refers_to_variable?
      aac = pattern.attribute_constraints.find{|aac| aac.value == ac.value}
      return aac.nil? ? ac.value : attribute_reference(aac)
    elsif ac.value_type == RDF::XSD.string
      return "'#{clean_value(ac)}'"
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
  
  # order by, limit, etc.
  def modifiers
    ""
  end
  
end