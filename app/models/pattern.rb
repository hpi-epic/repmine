class Pattern < ActiveRecord::Base
  
  include RdfSerialization
  
  attr_accessible :name, :description, :ontology_ids, :swe_pattern_ids, :repository_name, :tag_list
  attr_accessor :ag_connection, :ag_alignment
  
  acts_as_taggable_on :tags
  
  as_enum :query_language, sql: 0, cypher: 1, sparql: 2, mongo_js: 3, gremlin: 4

  has_and_belongs_to_many :ontologies
  has_and_belongs_to_many :swe_patterns
  has_many :nodes, :dependent => :destroy

  # hooks
  before_create :create_repository_name!
  before_destroy :delete_repository!

  # validations
  validates :name, :presence => true
  validates :description, :presence => true  
  validates :ontologies, :length => {:minimum => 1, :too_short => "requires at least one selection"}
  
  def root_node
    return nodes.where(:root_node => true).first
  end
  
  def type_hierarchy()
    return ag_connection.type_hierarchy()
  end
  
  def possible_relations_between(source, target, oneway = false)
    if oneway
      return ag_connection.relations_with(source, target)
    else
      return ag_connection.relations_between(source, target)
    end
  end
  
  def possible_attributes_for(node_class)
    return ag_connection.attributes_for(node_class)
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
  
  def create_repository_name!
    self.repository_name = self.name.strip
    self.repository_name.gsub!("/", "_")
    self.repository_name.gsub!(" ", "_")
    self.repository_name.gsub!("#", "_")
    self.repository_name += "_" + SecureRandom.urlsafe_base64
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
    return concepts_used.select{|concept| matched.find{|match| match[:entity] == concept}.nil?  }
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
  
  def rdf_xml
    buffer = RDF::RDFXML::Writer.buffer(:prefixes => self.xml_prefixes) do |writer|
      writer.write_graph(rdf_statements)
    end
    return buffer
  end
  
  def rdf_statements
    graph = RDF::Graph.new()
    graph << nodes.collect{|qn| qn.rdf_statements}
    graph << relation_constraints.collect{|qn| qrc.rdf_statements}
    return graph
  end
  
  def xml_prefixes()
    prefixes = {
     :rdfs => RDF::RDFS,
     :owl => RDF::OWL
    }
    ontologies.each{|ont| prefixes[ont.short_prefix] = ont.url}
    return prefixes
  end
  
  # determines the correspondences we can identify from the selected input and our recent changes
  def infer_correspondences(selected_elements)
    return true
  end
  
  # determines which elements where added or updated since the last 'save' of the pattern
  def recent_changes()
    changes = {}
    changes[:nodes] = nodes.find(:all, :conditions => ["updated_at > ?", self.updated_at])
    changes[:attributes] = nodes.collect{|n| n.attribute_constraints.find(:all, :conditions => ["updated_at > ?", self.updated_at])}.flatten
    changes[:relations] = nodes.collect{|n| n.source_relation_constraints.find(:all, :conditions => ["updated_at > ?", self.updated_at])}.flatten
    return changes
  end

  # transforms a given set of elements into a proper graph
  def get_subgraph(elements)
    # TODO: implement me
  end
end
