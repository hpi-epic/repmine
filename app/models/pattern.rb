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
  
  def type_hierarchy()
    ag_connection.type_hierarchy()
  end
  
  def possible_relations_from_to(source, target, oneway = false)
    ag_connection.relations_with(source, target)
  end
  
  def possible_attributes_for(node_class)
    ag_connection.attributes_for(node_class)
  end
  
  def nodes
    pattern_elements.where(:type => "Node")
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
  
  def infer_correspondences!
    return []
  end
end
