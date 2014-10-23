class AttributeConstraint < PatternElement
  attr_accessible :value, :operator, :node
  belongs_to :node, :class_name => "PatternElement"
  
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
    return [rdf_type]
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.AttributeConstraint]
  end
end
