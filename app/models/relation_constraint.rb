class RelationConstraint < ActiveRecord::Base
  belongs_to :source, :class_name => "Node"
  belongs_to :target, :class_name => "Node"
  attr_accessible :relation_type, :min_cardinality, :max_cardinality, :min_path_length, :max_path_length, :source_id, :target_id
  
  include RdfSerialization
  
  def rdf_statements
    return [
      [resource, Vocabularies::GraphPattern.belongsTo, (source || target).pattern.resource]      
    ]
  end
  
  def url
    return (source || target).url + "/relation_constraints/#{id}"
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.RelationConstraint]
  end
  
  def used_concepts
    return [relation_type]
  end
  
  def possible_relations(source_type = nil, target_type = nil)
    return source.pattern.possible_relations_from_to(source_type || source.rdf_type, target_type || target.rdf_type)
  end
end
