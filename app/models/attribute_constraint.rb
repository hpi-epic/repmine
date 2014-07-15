class AttributeConstraint < ActiveRecord::Base
  attr_accessible :attribute_name, :value, :operator
  belongs_to :node
  
  include RdfSerialization
  
  def rdf_statements
    return []
  end
end
