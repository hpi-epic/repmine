class QueryCreator < Struct.new(:pattern)
  
  attr_accessor :query_string
  
  def query_string
    @query_string ||= build_query!
  end
  
  def build_query!
    raise "implement me!"
  end
  
  # override if your query language does not support underscores
  def pe_variable(pe)
    return pe.variable_name.to_sym
  end
  
end