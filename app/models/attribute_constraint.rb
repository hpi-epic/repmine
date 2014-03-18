class AttributeConstraint < ActiveRecord::Base
  attr_accessible :attribute_name, :value, :operator
  belongs_to :node
  
  include RdfSerialization
  
  def to_cypher
    return "#{query_node.query_variable}.#{attribute_name}! #{operator} #{value}"
  end
  
  def rdf_statements
    return []
  end
end
