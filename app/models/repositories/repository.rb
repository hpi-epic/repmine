class Repository < ActiveRecord::Base
  attr_accessible :name, :description, :host, :port, :db_name, :db_username, :db_password
  belongs_to :ontology
  has_many :monitoring_tasks, :dependent => :destroy
  validates :name, :presence => true

  # job object for logging purposes
  attr_accessor :job

  TYPES = {
    "RDF" => "RdfRepository",
    "RDBMS" => "RdbmsRepository",
    "Neo4j" => "Neo4jRepository"
  }

  after_create :build_ontology

  def self.model_name
    ActiveModel::Name.new(Repository)
  end

  # overwrite this if you need a different format
  def self.rdf_format
    "ttl"
  end

  def self.default_port
    return nil
  end

  def self.for_type(type, params = {})
    if TYPES.keys.include?(type)
      return class_eval(TYPES[type]).new(params)
    else
      raise "#{type} is not a valid Repository type"
    end
  end

  def editable_attributes
    return self.class.accessible_attributes.select{|at| !at.blank?}
  end

  def build_ontology
    ont_url = ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:extracted_ontologies_path] + name_url_safe
    self.ontology = ExtractedOntology.create(:short_name => self.name, :does_exist => false, :group => "Extracted", :url => ont_url)
    self.ontology.repository = self
    self.ontology.save!
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

  def extract_ontology!(in_background = false)
    ontology.remove_local_copy!
    ontology.update_attributes({:does_exist => false})
    create_ontology!(in_background)
    if File.exist?(ontology.local_file_path)
      ontology.update_attributes({:does_exist => true})
      ontology.load_to_dedicated_repository!
    end
  end

  def results_for_pattern(pattern, aggregations)
    qs = query_for_pattern(pattern, aggregations)
    puts "Executing query: #{qs}"
    results_for_query(query_for_pattern(pattern, aggregations))
  end

  def query_for_pattern(pattern, aggregations)
    return self.class.query_creator_class.new(pattern.translated_to(self), aggregations).query_string
  end

  def create_ontology!(in_background)
    if in_background && ontology_creation_job.nil?
      j = OntologyExtractionJob.new(progress_max: 100, repository_id: self.id)
      Delayed::Job.enqueue(j, :queue => ont_creation_queue)
    else
      analyze_repository
    end
  end

  def analyze_repository
    raise "implement 'analyze_repository' in #{self.class.name}"
  end

  def type_statistics
    raise "implement 'type_statistics' in #{self.class.name}"
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
    return custom_imports
  end

  # overwrite this if your repository needs custom information within the ontology
  def custom_imports
    return []
  end
end