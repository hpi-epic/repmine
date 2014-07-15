class Pattern < ActiveRecord::Base
  
  #include RdfSerialization
  
  attr_accessible :name, :description, :ontology_ids, :swe_pattern_ids, :repository_name, :tag_list, :original_query
  acts_as_taggable_on :tags
  
  as_enum :query_language, sql: 0, cypher: 1, sparql: 2, mongo_js: 3, gremlin: 4

  # relations
  has_and_belongs_to_many :ontologies
  has_and_belongs_to_many :swe_patterns
  has_many :nodes, :dependent => :destroy
  has_many :relation_constraints, :dependent => :destroy

  # hooks
  before_save :create_repository_name!
  before_destroy :delete_repository!

  # validations
  validates :name, :presence => true
  validates :ontologies, :length => {:minimum => 1}
  
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
    
    self.ontologies.each do |ontology|
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
    return AgraphConnection.new(self.repository_name)
  end
  
  def create_repository_name!
    self.repository_name = self.name.strip
    self.repository_name.gsub!("/", "_")
    self.repository_name.gsub!(" ", "_")
    self.repository_name.gsub!("#", "_")    
    self.repository_name += "_" + SecureRandom.urlsafe_base64
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
end
