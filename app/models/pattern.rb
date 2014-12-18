class Pattern < ActiveRecord::Base
  
  include RdfSerialization
  
  attr_accessible :name, :description, :tag_list, :ontology_id
  attr_accessor :ag_connection
  
  acts_as_taggable_on :tags

  belongs_to :ontology
  has_many :pattern_elements, :dependent => :destroy

  # validations
  validates :name, :presence => true
  validates :description, :presence => true
  validates :ontology, :presence => true
  
  # 'factories' for creating patterns needed for experiments
  def self.n_r_n_pattern(ontology, source_class, relation_type, target_class, name = "Generic N_R_N")
    p = Pattern.create(ontology_id: ontology.id, name: name, description: "Generic")
    source_node = p.create_node!
    source_node.rdf_type = source_class
    target_node = p.create_node!
    target_node.rdf_type = target_class
    relation = RelationConstraint.create(:source_id => source_node.id, :target_id => target_node.id)
    relation.rdf_type = relation_type
    return p
  end
  
  # routing through...
  def type_hierarchy()
    ag_connection.type_hierarchy()
  end
  
  def possible_relations_from_to(source, target, oneway = false)
    ag_connection.relations_with(source, target)
  end
  
  def possible_attributes_for(node_class)
    ag_connection.attributes_for(node_class)
  end
  
  # polymorphic finders....
  def nodes
    pattern_elements.where(:type => "Node")
  end
  
  def attribute_constraints
    pattern_elements.where(:type => "AttributeConstraint")
  end
  
  def relation_constraints
    pattern_elements.where(:type => "RelationConstraint")
  end
  
  def create_node!
    node = self.nodes.create!
    return node.becomes(Node)
  end
  
  def ag_connection
    ontology.ag_connection
  end
  
  def node_offset
    return nodes.collect{|n| n.attribute_constraints.empty? ? n.x : n.x + 280}.max
  end
  
  # fidelling with concepts
  def concept_count
    concepts_used.size
  end
  
  def concepts_used
    Set.new(nodes.collect{|n| n.used_concepts}.flatten)
  end
  
  def unmatched_concepts(ont)
    matched = match_concepts(ont)
    unmatched = pattern_elements.select{|pe| matched.find{|match| match.input_elements.include?(pe)}.nil?}
    return Set.new(unmatched.collect{|pe| pe.used_concepts}.flatten)
  end
  
  def match_concepts(ont)
    om = OntologyMatcher.new(ontology, ont)
    om.match!
    return om.get_substitutes_for(pattern_elements)
  end
  
  # RDF Serialization
  def rdf_statements
    return nodes.collect{|qn| qn.rdf}.flatten(1)
  end
  
  def custom_prefixes()
    return {ontology.short_prefix => ont.url}
  end
  
  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:patterns_path] + id.to_s
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.GraphPattern]
  end
end
