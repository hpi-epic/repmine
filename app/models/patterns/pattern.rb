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
  has_many :target_patterns, :class_name => "Pattern", :foreign_key => "pattern_id"

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

  def matched_elements(ont)
    return pattern_elements.select{|pe| not pe.matching_elements.where(:pattern_id => target_pattern(ont)).empty?}
  end
  
  def unmatched_elements(ont)
    return pattern_elements.select{|pe| pe.matching_elements.where(:pattern_id => target_pattern(ont)).empty?}
  end
  
  def target_pattern(ont)
    Pattern.where(:ontology_id => ont.id, :pattern_id => self).first
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
  
  def print!
    puts "Pattern: #{self.name}"
    puts "Pattern Elements: #{pattern_elements.collect{|pe| pe.rdf_type}}"
  end
  
  # RDF deserialization
  def self.from_graph(graph, pattern_node)
    pattern = Pattern.new()
    
    graph.build_query do |q|
      q.pattern([:element, Vocabularies::GraphPattern.belongsTo, pattern_node])
      q.pattern([:element, RDF.type, :type])
      q.pattern([:type, RDF::RDFS.subClassOf, Vocabularies::GraphPattern.PatternElement])
    end.run do |res|
      pattern_element = Kernel.const_get(res[:type].to_s.split("/").last).new
      pattern_element.rdf_node = res[:element]
      pattern_element.pattern = pattern
      pattern.pattern_elements << pattern_element
    end
    
    pattern.pattern_elements.each{|pe| pe.rebuild!(graph)}
    return pattern
  end

  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:patterns_path] + id.to_s
  end

  def rdf_types
    [Vocabularies::GraphPattern.GraphPattern]
  end
end
