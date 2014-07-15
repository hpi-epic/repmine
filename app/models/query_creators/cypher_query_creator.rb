class CypherQueryCreator < QueryCreator
  
  def create_query(pattern, repository)
    cypher = "START " + start(pattern.root_node) + "\n"
    cypher += "MATCH " + pattern.relation_constraints.collect{|rc| match(rc)}.join("--") + "\n"
    cypher += "WHERE " + pattern.nodes.collect{|node| where(node, repository)}.reject{|part| part.blank?}.join(" AND ") + "\n"
    cypher += "RETURN DISTINCT " + pattern.nodes.collect{|node| node.query_variable}.join(", ")
    return cypher
  end
  
  def start(node)
    start = node.query_variable + "="
    start += "node:node_auto_index(`#{Graph::TYPE_FIELD}`=\"" + rdf_type + "\")"
    return start
  end
  
  def match(rc)
    return "#{rc.source.query_variable}-[r#{rc.id}:`#{rc.relation_name}`#{rc.length_constraints}]-#{rc.target.query_variable}"
  end
  
  def length_constraints(rc)
    if rc.min_path_length.blank? && rc.max_path_length.blank?
      return ""
    else
      if rc.max_path_length.blank?
        return "#{rc.max_path_length || "*1"}"
      else
        return rc.max_path_length.strip == "*" ? "*" : "*#{rc.max_path_length}"
      end
    end
  end
  
  def where(node, repository)
    constraints = []
    type_constraints = ["#{node.query_variable}.`#{repository.type_field}` = \"#{node.rdf_type}\""]
    types = repository.type_hierarchy()
    types[rdf_type][:subclasses].each_pair do |subcl, name|
      type_constraints << ["#{node.query_variable}.`#{repository.type_field}` = \"#{subcl}\""]
    end
    constraints << ["(" + type_constraints.join(" OR ") + ")"]
    return constraints.concat(node.attribute_constraints.collect{|ac| attribute_constraint(ac)}).join(" AND ")
  end
  
  def attribute_constraint(ac)
    return "#{ac.node.query_variable}.#{ac.attribute_name}! #{ac.operator} #{ac.value}"
  end
  
end