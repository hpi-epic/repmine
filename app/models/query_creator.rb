class QueryCreator < Struct.new(:pattern, :repository)
  
  # takes a pattern, returns a query string
  def query_string
    raise "implement query_string() in #{self.class.name} to provide queries in the necessary language!"
  end
  
end