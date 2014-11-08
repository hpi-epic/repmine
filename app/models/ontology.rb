require 'rdf/turtle'

class Ontology < ActiveRecord::Base
  attr_accessible :url, :description, :short_name, :does_exist, :group
  attr_accessor :ag_connection, :rdf_graph
  
  validates_url :url
  
  validates :url, :uniqueness => true
  
  has_and_belongs_to_many :patterns
  before_validation :set_ontology_url! ,:set_short_name_if_empty!
  after_create :load_to_dedicated_repository!
  before_destroy :delete_repository!
  
  def set_short_name_if_empty!
    self.short_name = url.split("/").last.split("\.").first if short_name.blank?
  end
  
  def set_ontology_url!
    self.url = ont_url if url.blank?
  end
  
  def load_to_repository!(repo_name)
    download!
    ag_connection(repo_name).insert_file!(local_file_path)
  end
  
  def ag_connection(repo_name = nil)
    @ag_connection ||= AgraphConnection.new(repo_name || repository_name)
  end
  
  def delete_repository!
    ag_connection.delete!
  end
  
  def load_to_dedicated_repository!
    ag_connection(repository_name).clear!
    load_to_repository!(repository_name)
  end
  
  def type_hierarchy
    return ag_connection.type_hierarchy
  end
  
  def repository_name
    return id.nil? ? self.short_name : "ontology_#{self.id}"
  end
  
  def imports()
    imps = Set.new()
    rdf_graph.query(:predicate => RDF::OWL.imports).each do |res|
      imp_url = res.object.to_s
      imps << Ontology.where("url = ?", imp_url).first_or_create unless imp_url == Vocabularies::SchemaExtraction.to_s
    end
    return imps
  end
  
  def vocabulary_class_name
    return short_name.gsub("#", "_").gsub("-", "_").gsub(".owl", "").gsub(".rdf", "").camelcase
  end
  
  # loads an ontology from a url
  def rdf_graph
    RDF::Graph.load(self.url)
  end
  
  def get_url
    return url
  end
  
  def ont_url
    return url
  end
  
  def local_file_path
    return Rails.root.join("public", "ontologies", "tmp", url.split("/").last)
  end
  
  def download!()
    File.open(local_file_path, "w+"){|f| f.puts rdf_xml} unless File.exist?(local_file_path)
  end
  
  # prefixes for the graph. not needed for imported ontologies
  def xml_prefixes
    return []
  end
  
  def rdf_xml
    RestClient.get(self.url).body
  end
  
  def element_class_for_rdf_type(rdf_type)
    ag_connection.element_class_for_rdf_type(rdf_type)
  end
end