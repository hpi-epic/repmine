class Pattern < ActiveRecord::Base
  
  include RdfSerialization
  
  attr_accessible :name, :description, :ontology_ids, :swe_pattern_ids, :tag_list
  attr_accessor :ag_connection
  
  acts_as_taggable_on :tags
  
  as_enum :query_language, sql: 0, cypher: 1, sparql: 2, mongo_js: 3, gremlin: 4

  has_and_belongs_to_many :ontologies
  has_and_belongs_to_many :swe_patterns
  has_many :pattern_elements, :dependent => :destroy

  # hooks
  before_destroy :delete_repository!

  # validations
  validates :name, :presence => true
  validates :description, :presence => true  
  validates :ontologies, :length => {:minimum => 1, :too_short => "requires at least one selection"}
  
  def type_hierarchy()
    return ag_connection.type_hierarchy()
  end
  
  def possible_relations_from_to(source, target, oneway = false)
    return ag_connection.relations_with(source, target)
  end
  
  def possible_attributes_for(node_class)
    return ag_connection.attributes_for(node_class)
  end
  
  def nodes
    pattern_elements.where(:type => "Node")
  end
  
  def create_node!
    node = self.nodes.create!
    return node.becomes(Node)
  end
    
  def initialize_repository!
    imported = Set.new(self.ontologies)
    ontologies.each do |ontology|
      (ontology.imports() - imported).each do |ont|
        ont.load_to_repository!(self.repository_name)
      end
      imported.merge(ontology.imports)
      ontology.load_to_repository!(self.repository_name)
    end
    ag_connection.remove_duplicates!
  end
  
  def delete_repository!
    ag_connection.delete!
  end
  
  def ag_connection
    @ag_connection ||= AgraphConnection.new(self.repository_name)
    return @ag_connection
  end
  
  def prepare_translation!(target_ontology)
    target_ontology.load_to_repository!(self.repository_name)
  end
  
  def repository_name
    return "pattern_#{self.id}"
  end
  
  def comprehensive_ontology
    return ontologies.size == 1 ? ontologies.first : create_comprehensive_ontology
  end
  
  def create_comprehensive_ontology
    g = RDF::Graph.new()
    ontologies.each{|o| g.load(o.url)}
    name = "pattern_tmp_#{self.id}"
    ont = ExtractedOntology.new(:short_name => name)
    ont.set_ontology_url
    ont.rdf_graph = g
    return ont
  end
  
  def concept_count
    concepts_used.size
  end
  
  def concepts_used
    Set.new(nodes.collect{|n| n.used_concepts}.flatten)
  end
  
  def unmatched_concepts(ontology)
    matched = match_concepts(ontology)
    return concepts_used.select{|concept| matched.find{|match| match[:entity] == concept}.nil?}
  end
  
  def match_concepts(ontology)
    om = OntologyMatcher.new(self, ontology)
    om.match!
    return concepts_used.collect{|concept| om.get_substitutes_for(concept)}.flatten
  end
  
  def reset!
    # first remove all newly created nodes...
    nodes.find(:all, :conditions => ["created_at > ?", self.updated_at]).each{|node| node.destroy}
    # then we reset the remainder
    nodes.each{|node| node.reset!}
    self.reload
  end
  
  # RDF Serialization
  def rdf_statements
    return nodes.collect{|qn| qn.rdf}.flatten(1)
  end
  
  def custom_prefixes()
    prefixes = {}
    ontologies.each{|ont| prefixes[ont.short_prefix] = ont.url}
    return prefixes
  end
  
  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:patterns_path] + id.to_s
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.GraphPattern]
  end
  
  # determines the correspondences we can identify from the selected input and our recent changes
  def infer_correspondences(selected_elements)
    true
  end
  
  # determines which elements where added or updated since the last 'save' of the pattern
  def recent_changes()
    changes = {}
    changes[:nodes] = nodes.find(:all, :conditions => ["updated_at > ?", self.updated_at])
    changes[:attributes] = nodes.collect{|n| n.attribute_constraints.find(:all, :conditions => ["updated_at > ?", self.updated_at])}.flatten
    changes[:relations] = nodes.collect{|n| n.source_relation_constraints.find(:all, :conditions => ["updated_at > ?", self.updated_at])}.flatten
    return changes
  end
end
