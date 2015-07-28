class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port, :db_name, :db_username, :db_password
  belongs_to :ontology
  has_many :monitoring_tasks, :dependent => :destroy
  validates :name, :presence => true

  # this is meant to temporarily hold a job object that loggin happens in...
  attr_accessor :job

  TYPES = ["RdfRepository", "RdbmsRepository", "Neo4jRepository"]

  # custom error class for ontology extraction
  class OntologyExtractionError < StandardError
  end

  after_create :build_ontology

  # overwrite this if you need a different format
  def self.rdf_format
    "ttl"
  end

  def self.default_port
    return nil
  end

  def self.for_type(type, params = {})
    if TYPES.include?(type)
      return class_eval(type).new(params)
    end
  end

  def editable_attributes
    return self.class.accessible_attributes.select{|at| !at.blank?}
  end

  def build_ontology
    ont_url = ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:extracted_ontologies_path] + name_url_safe
    self.ontology = ExtractedOntology.create(:short_name => self.name, :does_exist => false, :group => "Extracted", :url => ont_url)
    self.ontology.repository = self
    self.ontology.save
  end

  def name_url_safe
    return name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_') + "_#{self.id}"
  end

  def ontology_creation_job
    Delayed::Job.find_by_queue(ont_creation_queue)
  end

  def ont_creation_queue
    "ont_creation_#{self.id}"
  end

  def query_queue
    "queries_#{self.id}"
  end

  def query_jobs
    Delayed::Job.find_all_by_queue(query_queue)
  end

  def extract_ontology!
    ontology.remove_local_copy!
    ontology.update_attributes({:does_exist => false})
    errors = create_ontology!

    if File.exist?(ontology.local_file_path)
      ontology.update_attributes({:does_exist => true})
      ontology.load_to_dedicated_repository!
    end

    return errors
  end

  def results_for_pattern(pattern, aggregations, generate_csv = true)
    qs = query_for_pattern(pattern, aggregations)
    puts "Executing query: #{qs}"
    res, csv = execute(query_for_pattern(pattern, aggregations), generate_csv)
  end

  def query_for_pattern(pattern, aggregations)
    return self.class.query_creator_class.new(pattern, aggregations).query_string
  end

  def create_ontology!
    raise "implement #{create_ontology} for #{self.class.name} to create a RDFS+OWL ontology file for our repository"
  end

  def analyze_repository(job = nil)
    raise "implement 'analyze_repository' in #{self.class.name}"
  end

  def type_statistics
    raise "implement 'type_statistics' in #{self.class.name}"
  end

  def csv_data(results)
    CSV.generate do |csv|
      csv << results["columns"]
      results["data"].each{|data_row| csv << data_row}
    end
  end

  def execute(query, generate_csv)
    results = results_for_query(query)
    if generate_csv
      return results, csv_data(results)
    else
      return results
    end
  end

  def results_for_query(query)
    raise "implement 'results for query' in #{self.class.name}"
  end

  def log_status(msg, step)
    job.nil? ? puts(msg) : job.update_stage_progress(msg, :step => step)
  end

  def log_msg(msg)
    job.nil? ? puts(msg) : job.update_stage(msg)
  end

  def database_type
    "Generic"
  end

  def database_version
    return "1.0"
  end

  def self.query_creator_class
    SparqlQueryCreator
  end

  def imports
    return [RDF::Resource.new(Vocabularies::SchemaExtraction)].concat(custom_imports)
  end

  # overwrite this if your repository needs custom information within the ontology
  def custom_imports
    return []
  end
end