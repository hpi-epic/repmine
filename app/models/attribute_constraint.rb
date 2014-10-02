class AttributeConstraint < ActiveRecord::Base
  attr_accessible :attribute_name, :value, :operator, :node
  belongs_to :node
  
  include RdfSerialization
  
  def rdf_statements
    return [
      [resource, Vocabularies::GraphPattern.belongsTo, node.pattern.resource]
    ]
  end
  
  def url
    return node.url + "/attribute_constraints/#{id}"
  end
  
  def possible_attributes(rdf_type = nil)
    return node.pattern.possible_attributes_for(rdf_type || node.rdf_type)
  end
  
  def used_concepts
    return [attribute_name]
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.AttributeConstraint]
  end
end
