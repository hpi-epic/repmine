class RelationConstraint < PatternElement
  belongs_to :source, :class_name => "Node"
  belongs_to :target, :class_name => "Node"
  attr_accessible :min_cardinality, :max_cardinality, :min_path_length, :max_path_length, :source_id, :target_id

  before_save :assign_to_pattern!

  include RdfSerialization

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
    return pattern.possible_relations_from_to(source_type || source.rdf_type, target_type || target.rdf_type)
  end
end
