class RelationConstraint < ActiveRecord::Base
  belongs_to :source, :class_name => "Node"
  belongs_to :target, :class_name => "Node"
  attr_accessible :relation_type, :min_cardinality, :max_cardinality, :min_path_length, :max_path_length
  
  include RdfSerialization
  
  def rdf_statements
    return []
  end
  
  def self.from_source_to_target(source, target)
    rel_constraint = self.new()
    rel_constraint.source = source
    rel_constraint.target = target
    rel_constraint.save!
    return rel_constraint
  end
end
