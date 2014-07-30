class AttributeConstraint < ActiveRecord::Base
  attr_accessible :attribute_name, :value, :operator, :node
  belongs_to :node
  
  include RdfSerialization
  
  def rdf_statements
    return []
  end
  
  def possible_attributes(rdf_type = nil)
    return node.pattern.possible_attributes_for(rdf_type || node.rdf_type)
  end
end
