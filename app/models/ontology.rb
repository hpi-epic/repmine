require 'rdf/rdfxml'

class Ontology < ActiveRecord::Base
  attr_accessible :url, :description, :prefix_url, :short_name
  attr_accessor :ag_connection, :rdf_graph
  
  validates_url :url
  
  validates :url, :uniqueness => true
  validates :prefix_url, :uniqueness => true
  
  has_and_belongs_to_many :queries
  
  before_validation :set_prefix_if_empty, :set_short_name_if_empty
  
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
  
  def load_to_repository!(repository_name)
    # store it in a repository and remove all duplicates
    ag_connection = AgraphConnection.new(repository_name)
    ag_connection.insert_graph!(rdf_graph)
  end
  
  def imports()
    return Set.new(rdf_graph.query(:predicate => RDF::OWL.imports).collect do |res|
      Ontology.where("url = ? OR prefix_url = ?", res.object.to_s, res.object.to_s).first_or_create
    end)
  end
  
  def rdf_graph
    return @rdf_graph ||= load_ontology
  end
  
  def vocabulary_class_name
    return short_name.gsub("#", "_").gsub("-", "_").gsub(".owl", "").gsub(".rdf", "").camelcase
  end
  
  def load_ontology
    begin
      RDF::Graph.load(self.url)
    rescue
      # for http -> https redirects. will fail for others, so ok...
      RDF::Graph.load(HTTPClient.get(self.url).headers["Location"])
    end
  end
  
end
