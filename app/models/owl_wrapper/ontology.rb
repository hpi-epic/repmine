require 'rdf/turtle'

class Ontology < ActiveRecord::Base
  attr_accessible :url, :description, :short_name, :does_exist, :group
  attr_accessor :ag_connection, :rdf_graph, :type_hierarchy, :classes

  validates :url, :uniqueness => true, :presence => true
  validate :can_be_downloaded, :if => :load_immediately?

  has_many :patterns
  has_one :repository

  before_validation :set_short_name_if_empty!
  after_create :load_to_dedicated_repository!, :if => :load_immediately?
  before_destroy :delete_repository!

  def load_immediately?
    return true
  end

  def set_short_name_if_empty!
    self.short_name = url.split("/").last.split("\.").first if short_name.blank?
  end

  def can_be_downloaded
    begin
      download!
    rescue Exception => e
      errors.add(:url, "could not be reached for download: #{e.message}")
    end
  end

  def load_to_repository!(repo_name)
    if does_exist
      download!
      ag_connection(repo_name).insert_file!(local_file_path)
    end
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

  def type_hierarchy()
    @type_hierarchy ||= ag_connection.type_hierarchy(self)
  end

  def add_class(klazz)
    classes << klazz
  end

  def classes
    @classes ||= Set.new()
    return @classes
  end

  def clear!
    @classes = Set.new()
  end

  def repository_name
    return id.nil? ? self.short_name : "ontology_#{self.id}"
  end

  # expose the agraph_connection interface to ontology users
  def method_missing(sym, *args, &block)
    return ag_connection.send(sym, *args, &block) if ag_connection.respond_to?(sym)
    super(sym, *args, &block)
  end

  def imports()
    imps = Set.new()
    rdf_graph.query(:predicate => RDF::OWL.imports).each do |res|
      imp_url = res.object.to_s
      imps << Ontology.where("url = ?", imp_url).first_or_create
    end
    return imps
  end

  # loads an ontology from a url
  def rdf_graph
    RDF::Graph.load(self.url)
  end

  def very_short_name
    return short_name.split("#").last.split(".").first.underscore
  end

  def local_file_path
    return Rails.root.join("public", "ontologies", "tmp", url.split("/").last).to_s
  end

  def download!()
    unless File.exist?(local_file_path)
      begin
        File.open(local_file_path, "wb"){|f| f.puts rdf_xml}
      rescue Exception => e
        remove_local_copy!
        raise e
      end
    end
  end

  def remove_local_copy!
    File.delete(local_file_path) if File.exist?(local_file_path)
  end

  # prefixes for the graph. not needed for imported ontologies
  def xml_prefixes
    return []
  end

  def rdf_xml
    RestClient.get(self.url).body
  end

  def download_url
    return url
  end

  def self.grouped
    groups = pluck(:group).uniq.map do |group|
      [group, where(:does_exist => true, :group => group).collect{|ont| [ont.short_name, ont.id]}]
    end
    groups.reject{|group| group[1].empty?}
  end
end

require_dependency 'agraph_connection'