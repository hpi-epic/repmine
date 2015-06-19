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
  validates :source, :presence => true
  validates :target, :presence => true
    
  before_save :assign_to_pattern!, :assign_ontology!

  def rdf_mappings
    super.merge({
      Vocabularies::GraphPattern.sourceNode => {:property => :source},
      Vocabularies::GraphPattern.targetNode => {:property => :target},
      Vocabularies::GraphPattern.min_cardinality => {:property => :max_cardinality, :literal => true},
      Vocabularies::GraphPattern.max_cardinality => {:property => :min_cardinality, :literal => true},
      Vocabularies::GraphPattern.min_path_length => {:property => :min_path_length, :literal => true},
      Vocabularies::GraphPattern.max_path_length => {:property => :max_path_length, :literal => true}
    })
  end
  
  def rdf_statements
    stmts = super
    stmts << [resource, Vocabularies::GraphPattern.sourceNode, source.resource]
    stmts << [resource, Vocabularies::GraphPattern.targetNode, target.resource]
    stmts << [resource, Vocabularies::GraphPattern.min_cardinality, RDF::Literal.new(min_cardinality)] unless min_cardinality.blank?
    stmts << [resource, Vocabularies::GraphPattern.max_cardinality, RDF::Literal.new(max_cardinality)] unless max_cardinality.blank?
    stmts << [resource, Vocabularies::GraphPattern.min_path_length, RDF::Literal.new(min_path_length)] unless min_path_length.blank?
    stmts << [resource, Vocabularies::GraphPattern.max_path_length, RDF::Literal.new(max_path_length)] unless max_path_length.blank?
    return stmts
  end

  def assign_to_pattern!
    self.pattern = source.pattern unless source.nil?
  end
  
  def assign_ontology!
    self.ontology = source.ontology if ontology.nil?
  end

  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.RelationConstraint]
  end

  def possible_relations(source_type = nil, target_type = nil)
    return ontology.relations_with(source_type || source.rdf_type, target_type || target.rdf_type)
  end
  
  def pretty_string
    str = " #{type_expression.fancy_string(true)}"
    str += " (#{min_cardinality.blank? ? 0 : min_cardinality},#{max_cardinality.blank? ? '*' : max_cardinality})"
    str += "[#{min_path_length.blank? ? 1 : min_path_length},#{max_path_length.blank? ? 1 : max_path_length}] "
  end
end
