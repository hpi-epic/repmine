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
    "(#{pe_variable(node)}:`#{node.rdf_type}`)"
  end
  
  def relation_reference(rel)
    "[:`#{rel.rdf_type}`]"
  end
  
  def return_values
    pattern.nodes.collect{|node| pe_variable(node)}.join(", ")
  end
  
  def parameters
    str = pattern.attribute_constraints.collect do |ac|
      "#{pe_variable(ac.node)}.#{ac.rdf_type} #{ac.operator} #{ac.value}"
    end.join(" AND ")
    return str.empty? ? "" : "WHERE #{str}"
  end
  
  # order by, limit, etc.
  def modifiers
    ""
  end
  
end