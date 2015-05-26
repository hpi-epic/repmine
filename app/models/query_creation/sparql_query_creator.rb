class SparqlQueryCreator < QueryCreator

  attr_accessor :filter, :where, :variables

  def initialize(*args)
    @where = []
    @filter = []
    @variables = []
    super
  end

  def build_query!
    @sparql = SPARQL::Client.new(RDF::Repository.new())
    fill_variables!
    fill_where_clause!
    query = @sparql.select(*variables).where(*where)
    filter.each{|filter| query.filter(filter)}
    return query.to_s
  end

  def fill_where_clause!
    pattern.nodes.each do |node|
      where << [pe_variable(node), RDF.type, RDF::Resource.new(node.rdf_type)]
    end
    pattern.nodes.each do |node|
      node.source_relation_constraints.each do |rc|
        where << [pe_variable(node), rc.type_expression.resource, pe_variable(rc.target)]
      end
      node.attribute_constraints.each do |ac|
        meth = "pattern_for_ac_#{AttributeConstraint::OPERATORS.key(ac.operator)}".to_sym
        self.send(meth, node, ac) unless !self.respond_to?(meth) || ac.value.nil?
      end
    end
  end

  def fill_variables!
    @variables = pattern.nodes.collect{|n| pe_variable(n)}
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
    filter << "regex(?#{pe_variable(ac)}, #{ac.value.gsub("\/", "")})"
    where << [pe_variable(node), ac.type_expression.resource, pe_variable(ac)]
  end

  def pattern_for_ac_var(node, ac)
    where << [pe_variable(node), ac.type_expression.resource, ac.variable_name.to_sym]
  end
end
