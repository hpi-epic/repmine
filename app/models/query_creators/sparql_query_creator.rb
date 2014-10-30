class SparqlQueryCreator < QueryCreator
  
  def query_string
    return query_object.to_s
  end
  
  def query_object
    sparql = SPARQL::Client.new(RDF::Repository.new())
    return sparql.select(*variables).where(*where_clause)
  end
  
  def variables
    return pattern.nodes.collect{|n| node_variable(n)}
  end
  
  def where_clause
    patterns = []
    pattern.nodes.each do |node|
      patterns << [node_variable(node), RDF.type, RDF::Resource.new(node.rdf_type)]
    end
    pattern.nodes.each do |node|
      node.source_relation_constraints.each do |rc|
        patterns << [node_variable(node), rc.rdf_type, node_variable(rc.target)]
      end
      node.attribute_constraints.each do |ac|
        patterns << pattern_for_attribute_constraint(node, ac) unless ac.value.nil?
      end
    end
    return patterns
  end
  
  def node_variable(node)
    return "node_#{node.id}".to_sym
  end
  
  def pattern_for_attribute_constraint(node, ac)
    return [node_variable(node), ac.rdf_type, ac.value]
  end
  
end