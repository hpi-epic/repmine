class AttributeConstraint < PatternElement
  attr_accessible :value, :operator, :node
  belongs_to :node, :class_name => "PatternElement"
  
  before_save :assign_to_pattern!
  
  include RdfSerialization
  
  OPERATORS = ["?", "~=", "=", "<", ">", "!"]
  
  def rdf_statements
    return [
      [resource, Vocabularies::GraphPattern.belongsTo, pattern.resource]
    ]
  end
  
  def assign_to_pattern!
    self.pattern = node.pattern unless node.nil?
  end
  
  def url
    return pattern.url + "/attribute_constraints/#{id}"
  end
  
  def possible_attributes(rdf_type = nil)
    return pattern.possible_attributes_for(rdf_type || node.rdf_type)
  end
  
  def used_concepts
    return [rdf_type]
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.AttributeConstraint]
  end
end
