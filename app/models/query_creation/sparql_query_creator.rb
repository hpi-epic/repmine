class SparqlQueryCreator < QueryCreator

  attr_accessor :filter, :where, :variables, :groupings

  def initialize(*args)
    @where = []
    @filter = []
    @variables = []
    @groupings = []
    super
  end

  def build_query
    @sparql = SPARQL::Client.new(RDF::Repository.new())
    fill_variables
    fill_where_clause
    query = @sparql.select(*variables).where(*where)
    query.group_by(*groupings) unless groupings.empty?
    filter.each{|filter| query.filter(filter)}
    return clean_query_string(query.to_s)
  end

  # SPARQL Client is incapable of doing count sum and stuff like that...
  def clean_query_string(query_str)
    return query_str.gsub(" ?(", " (")
  end

  def fill_where_clause
    pattern.nodes.each do |node|
      where << [pe_variable(node), RDF.type, RDF::Resource.new(node.rdf_type)]
    end

    pattern.relation_constraints.each do |rc|
      where << [pe_variable(rc.source), rc.type_expression.resource, pe_variable(rc.target)]
    end

    pattern.attribute_constraints.each do |ac|
      meth = "pattern_for_ac_#{AttributeConstraint::OPERATORS.key(ac.operator)}".to_sym
      self.send(meth, ac.node, ac) unless !self.respond_to?(meth) || ac.value.nil?
    end
  end

  def fill_variables
    @variables = pattern.returnable_elements(aggregations).collect{|n| return_variable(n)}
  end

  def return_variable(pe)
    agg = aggregation_for_element(pe)
    if agg.nil?
      pe_variable(pe)
    elsif agg.is_grouping?
      @groupings << pe_variable(pe)
      "(?#{pe_variable(pe)} AS ?#{agg.alias_name})"
    elsif agg.operation.nil?
      "(?#{pe_variable(pe)} AS ?#{agg.alias_name})"
    else
      "(#{agg.operation.upcase}(#{agg.distinct ? "DISTINCT " : ""}?#{pe_variable(pe)}) AS ?#{agg.alias_name})"
    end
  end

  def pattern_for_ac_equals(node, ac)
    if ac.refers_to_variable?
      where << [pe_variable(node), ac.type_expression.resource, pe_variable(ac)]
      filter << "?#{pe_variable(ac)} = #{ac.value}"
    else
      where << [pe_variable(node), ac.type_expression.resource, ac.value]
    end
  end

  def pattern_for_ac_regex(node, ac)
    filter << "regex(?#{pe_variable(ac)}, \"#{ac.value.gsub("\/", "")}\")"
    where << [pe_variable(node), ac.type_expression.resource, pe_variable(ac)]
  end

  def pattern_for_ac_var(node, ac)
    where << [pe_variable(node), ac.type_expression.resource, ac.variable_name.to_sym]
  end
end
