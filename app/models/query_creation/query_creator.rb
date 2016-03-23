class QueryCreator < Struct.new(:pattern, :aggregations)

  attr_accessor :query_string

  def query_string
    @query_string ||= build_query
  end

  def build_query()
    raise "implement me!"
  end

  def aggregation_for_element(pe)
    (aggregations || []).find{|agg| agg.pattern_element_id == pe.id}
  end

  # override if your query language does not support underscores
  def pe_variable(pe)
    pe.name.underscore.to_sym
  end
end