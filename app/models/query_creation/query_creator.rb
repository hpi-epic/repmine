class QueryCreator < Struct.new(:pattern, :aggregations, :monitoring_task_id)

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
    pe.name.squish.downcase.tr(" ","_").to_sym
  end

  def update_query(filters, values, ontology)
    raise "implement an update query with simple attribute value filters and target values to write"
  end

  def self.language
    return name.gsub("QueryCreator", "")
  end
end