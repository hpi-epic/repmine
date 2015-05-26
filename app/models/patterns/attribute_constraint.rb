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
  attr_accessible :value, :operator, :node
  belongs_to :node, :class_name => "PatternElement"

  before_save :assign_to_pattern!

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
      Vocabularies::GraphPattern.attributeValue => {:property => :value, :literal => true}
    })
  end

  def assign_to_pattern!
    self.pattern = node.pattern unless node.nil?
  end

  def possible_attributes(rdf_type = nil)
    return pattern.ontology.attributes_for(rdf_type || node.rdf_type)
  end

  def refers_to_variable?
    return contains_variable?(self.value)
  end

  def variable_name
    value.start_with?("?") ? value[1..-1] : value
  end

  def used_concepts
    return [rdf_type]
  end

  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.AttributeConstraint]
  end
end
