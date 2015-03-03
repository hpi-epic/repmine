# == Schema Information
#
# Table name: patterns
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  ontology_id :integer
#  type        :string(255)
#  pattern_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

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

  def node_offset
    return nodes.collect{|n| n.attribute_constraints.empty? ? n.x : n.x + 280}.max
  end

  # fidelling with concepts
  def concept_count
    used_concepts.size
  end

  def used_concepts
    Set.new(nodes.collect{|n| n.used_concepts}.flatten)
  end

  def unmatched_concepts(ont)
    used_concepts - matched_concepts(ont)
  end

  def matched_concepts(ont)
    ontology_matcher(ont).matched_concepts
  end
  
  def ontology_matcher(ont)
    return OntologyMatcher.new(self.ontology, ont)
  end
  
  # some comparison
  def equal_to?(other)
    if self == other
      return true
    else
      return self.pattern_elements.find{|pe| other.pattern_elements.select{|ope| pe.equal_to?(ope)}.size != 1}.nil?
    end
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
