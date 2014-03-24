class RelationConstraint < ActiveRecord::Base
  belongs_to :source, :class_name => "Node"
  belongs_to :target, :class_name => "Node"
  attr_accessible :relation_type, :min_cardinality, :max_cardinality, :min_path_length, :max_path_length
  
  include RdfSerialization
  
  def to_cypher
    return "#{source.query_variable}-[r#{id}:`#{relation_name}`#{length_constraints}]-#{target.query_variable}"
  end
  
  def length_constraints
    if min_path_length.blank? && max_path_length.blank?
      return ""
    else
      if max_path_length.blank?
        return "#{max_path_length || "*1"}"
      else
        return max_path_length.strip == "*" ? "*" : "*#{max_path_length}"
      end
    end
  end
  
  def possible_relations
    return source.possible_relations_to(target)
  end
  
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
