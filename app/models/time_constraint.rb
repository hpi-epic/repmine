class TimeConstraint < ActiveRecord::Base
  # attr_accessible :title, :body
  
  include RdfSerialization  
  
  def rdf_statements
    return []
  end
end
