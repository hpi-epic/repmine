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

class RelationConstraint < PatternElement
  belongs_to :source, :class_name => "Node"
  belongs_to :target, :class_name => "Node"
  attr_accessible :min_cardinality, :max_cardinality, :min_path_length, :max_path_length, :source_id, :target_id

  before_save :assign_to_pattern!

  def rdf_statements
    return [
      [resource, Vocabularies::GraphPattern.belongsTo, pattern.resource]
    ]
  end

  def assign_to_pattern!
    self.pattern = source.pattern unless source.nil?
  end

  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.RelationConstraint]
  end

  def possible_relations(source_type = nil, target_type = nil)
    return pattern.ontology.relations_with(source_type || source.rdf_type, target_type || target.rdf_type)
  end
end
