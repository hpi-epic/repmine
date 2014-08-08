require 'rdf/turtle'

class Ontology < ActiveRecord::Base
  attr_accessible :url, :description, :prefix_url, :short_name
  attr_accessor :ag_connection, :rdf_graph
  
  validates_url :url
  
  validates :url, :uniqueness => true
  validates :prefix_url, :uniqueness => true
  
  has_and_belongs_to_many :patterns
  before_validation :set_ontology_url, :set_prefix_if_empty ,:set_short_name_if_empty
    
  def set_prefix_if_empty
    if prefix_url.blank?
      self.prefix_url = url
    end
  end
  
  def set_short_name_if_empty
    if short_name.blank?
      self.short_name = url.split("/").last.split("\.").first
    end
  end
  
  def set_ontology_url
    if url.blank?
      self.url = ont_url
    end
  end
  
  def load_to_repository!(repository_name)
    # store it in a repository and remove all duplicates
    ag_connection = AgraphConnection.new(repository_name)
    download!
    ag_connection.insert_file!(local_file_path)
  end
  
  def imports()
    return Set.new(rdf_graph.query(:predicate => RDF::OWL.imports).reject{|res| 
      res.object.to_s == Vocabularies::SchemaExtraction.to_s}.collect do |res|
        Ontology.where("url = ? OR prefix_url = ?", res.object.to_s, res.object.to_s).first_or_create
      end
    )
  end
  
  def rdf_graph
    return @rdf_graph ||= load_ontology
  end
  
  def vocabulary_class_name
    return short_name.gsub("#", "_").gsub("-", "_").gsub(".owl", "").gsub(".rdf", "").camelcase
  end
  
  # loads an ontology from a url
  def load_ontology
    RDF::Graph.load(self.url)
  end
  
  def get_url
    return url
  end
  
  def local_file_path
    return Rails.root.join("public", "ontologies", "tmp", url.split("/").last)
  end
  
  def download!(force = false)
    if !File.exist?(local_file_path) || force
      File.open(local_file_path, "w+"){|f| f.puts rdf_xml} 
    end
  end
  
  # prefixes for the graph. not needed for imported ontologies
  def xml_prefixes
    return []
  end
  
  def rdf_xml
    RestClient.get(self.url).body
  end
end