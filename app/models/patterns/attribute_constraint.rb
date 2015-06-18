# == Schema Information
#
# Table name: pattern_elements
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pattern_id      :integer
#  node_id         :integer
#  value           :string(255)
#  operator        :string(255)
#  min_cardinality :string(255)
#  max_cardinality :string(255)
#  min_path_length :string(255)
#  max_path_length :string(255)
#  source_id       :integer
#  target_id       :integer
#  x               :integer          default(0)
#  y               :integer          default(0)
#  is_group        :boolean          default(FALSE)
#

class AttributeConstraint < PatternElement
  attr_accessible :value, :operator, :node, :x, :y
  belongs_to :node, :class_name => "PatternElement"
  validates :node, :presence => true
  before_save :assign_to_pattern!, :assign_ontology!

  OPERATORS = {
    :var => "?",
    :regex => "=~",
    :equals => "=",
    :less_than => "<",
    :greater_than => ">",
    :not => "!"
  }
  
  def rdf_mappings
    super.merge({
      Vocabularies::GraphPattern.attributeValue => {:property => :value, :literal => true},
      Vocabularies::GraphPattern.attributeOperator => {:property => :operator, :literal => true},
      Vocabularies::GraphPattern.node => {:property => :node},
    })
  end
  
  def rdf_statements
    stmts = super
    stmts << [resource, Vocabularies::GraphPattern.node, node.resource]
    stmts << [resource, Vocabularies::GraphPattern.attributeValue, value]
    stmts << [resource, Vocabularies::GraphPattern.attributeOperator, operator]
    return stmts
  end
  
  def value_type
    ontology.attribute_range(rdf_type)
  end

  def assign_to_pattern!
    self.pattern = node.pattern unless node.nil?
  end
  
  def assign_ontology!
    self.ontology = node.ontology if ontology.nil?
  end

  def possible_attributes(rdf_type = nil)
    return ontology.attributes_for(rdf_type || node.rdf_type)
  end

  def refers_to_variable?
    return contains_variable?(self.value)
  end
  
  def is_variable?
    operator == OPERATORS[:var]
  end

  def variable_name
    value.start_with?("?") ? value[1..-1] : value
  end

  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.AttributeConstraint]
  end
  
  def pretty_string
    "#{type_expression.fancy_string(true)} #{operator} #{value}"
  end
end