class Query < ActiveRecord::Base
  
  include RdfSerialization
  
  #rdf_type()
  
  attr_accessible :name, :description, :ontology_ids, :repository_name, :tag_list
  acts_as_taggable_on :tags

  # relations
  has_and_belongs_to_many :ontologies
  has_many :query_nodes, :dependent => :destroy
  has_many :query_relation_constraints, :dependent => :destroy

  # hooks
  before_save :create_repository_name!
  before_destroy :delete_repository!

  # validations
  validates :name, :presence => true
  validates :ontologies, :length => { :minimum => 1}
  
  def root_node
    return query_nodes.where(:root_node => true).first
  end
  
  def to_cypher(graph)
    cypher = "START " + root_node.start_info() + "\n"
    cypher += "MATCH " + query_relation_constraints.collect{|qrc| qrc.to_cypher}.join("--") + "\n"
    cypher += "WHERE " + query_nodes.collect{|node| node.cypher_constraints(graph)}.reject{|part| part.blank?}.join(" AND ") + "\n"
    cypher += "RETURN DISTINCT " + query_nodes.collect{|node| node.query_variable}.join(", ")
    puts cypher
    return cypher
  end
  
  def all_types_with_relations_and_attributes()
    return ag_connection.all_classes_for_repository(repository_name)
  end
  
  def possible_relations_between(source, target)
    return ag_connection.relations_between(source, target)
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
    graph << query_nodes.collect{|qn| qn.rdf_statements}
    graph << query_relation_constraints.collect{|qn| qrc.rdf_statements}
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
