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
  attr_accessor :ag_connection, :layouted_graph

  acts_as_taggable_on :tags

  has_and_belongs_to_many :ontologies
  has_many :pattern_elements, :dependent => :destroy
  has_many :target_patterns, :class_name => "Pattern", :foreign_key => "pattern_id"

  # validations
  validates :name, :presence => true
  validates :description, :presence => true
  validates :ontologies, :length => {:minimum => 1, :message=>"At least one ontology is required!" }

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
  
  def create_node!(ontology)
    node = self.nodes.create!(:ontology_id => ontology.id)
    return node.becomes(Node)
  end

  def matched_elements(onts)
    return pattern_elements.select{|pe| not pe.matching_elements.where(:ontology_id => onts).empty?}
  end
  
  def unmatched_elements(onts)
    return pattern_elements.select{|pe| pe.matching_elements.where(:ontology_id => onts).empty?}
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
    return pattern_elements.collect{|pe| pe.rdf}.flatten(1)
  end

  def custom_prefixes()
    prefixes = {}
    ontologies.each{|ontology| prefixes[ontology.short_prefix] = ont.url}
    return prefixes
  end
  
  def print!
    puts "Pattern: #{self.name}"
    puts "Pattern Elements: #{pattern_elements.collect{|pe| pe.rdf_type}}"
  end
  
  # RDF deserialization
  def self.from_graph(graph, pattern_node, ont)
    pattern = Pattern.new()
    
    graph.build_query do |q|
      q.pattern([:element, Vocabularies::GraphPattern.belongsTo, pattern_node])
      q.pattern([:element, RDF.type, :type])
      q.pattern([:type, RDF::RDFS.subClassOf, Vocabularies::GraphPattern.PatternElement])
    end.run do |res|
      pattern_element = Kernel.const_get(res[:type].to_s.split("/").last).new
      pattern_element.rdf_node = res[:element]
      pattern_element.pattern = pattern
      pattern_element.ontology = ont
      pattern.pattern_elements << pattern_element
    end
    
    pattern.pattern_elements.each{|pe| pe.rebuild!(graph)}
    return pattern
  end
    
  def graphviz_graph
    g = GraphViz.new("#{id}", {:type => :digraph, :splines => true})
    node_cache = {}
    nodes.each do |node| 
      node_cache[node] = g.add_node(node.id.to_s, {:label => node.pretty_string})
      node.attribute_constraints.each do |ac| 
        ac_node = g.add_node(ac.id.to_s, {:shape => "box", :label => ac.pretty_string})
        g.add_edge(node_cache[node], ac_node)
      end
    end
    relation_constraints.each do |rc|
      g.add_edge(node_cache[rc.source], node_cache[rc.target], {:label => rc.pretty_string, :labeldistance => 10.0, :labelfloat => false})
    end
    return g
  end
  
  def auto_layout!()
    graphviz_graph.output(:dot => Rails.root.join("tmp", "pattern_layouts", "#{id}.dot"))
    graphviz_graph.output(:png => Rails.root.join("tmp", "pattern_layouts", "#{id}.png"))    
    @layouted_graph = GraphViz.parse(Rails.root.join("tmp", "pattern_layouts", "#{id}.dot").to_s)
  end
  
  def position_for_element(element)
    point = layouted_graph.get_node(element.id.to_s)["pos"].point
    point[1] += 90
    point[1] *= 1.2
    point[0] *= 1.4
    return point
  end
  
  def node_offset
    furthest = (nodes + attribute_constraints).sort_by{|pe| position_for_element(pe)[0]}.last
    return position_for_element(furthest)[0]
  end
  
  def layouted_graph
    @layouted_graph || auto_layout!
  end

  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:patterns_path] + id.to_s
  end

  def rdf_types
    [Vocabularies::GraphPattern.GraphPattern]
  end
end
