class MonitoringTask < ActiveRecord::Base
  attr_accessible :repository_id, :measurable_id

  has_many :attribute_constraints, dependent: :destroy
  belongs_to :repository
  belongs_to :measurable

  before_destroy :remove_results

  def self.create_multiple(measurable_ids, repository_id)
    return measurable_ids.collect do |m_id|
      self.where(:measurable_id => m_id,  :repository_id => repository_id).first_or_create!
    end.uniq
  end

  def remove_results
    FileUtils.rm_rf(result_file)
  end

  def has_latest_results?
    File.exist?(result_file)
  end

  def results_file(ending)
    return Rails.root.join("public","data","#{filename}.#{ending}").to_s
  end

  def filename
    "#{measurable.class.name}_#{measurable_id}_repo_#{repository.id}"
  end

  def result_file
    results_file("json")
  end

  def results
    return Oj.load(File.open(result_file).read)
  end

  def enqueue
    job = QueryExecutionJob.new(:monitoring_task_id => id)
    Delayed::Job.enqueue(job, :queue => repository.query_queue)
  end

  def run(job = nil)
    repository.job = job
    res = begin
      measurable.run(self)
    rescue Exception => e
      return []
    end
    repository.job = nil
    File.open(result_file, "wb"){|f| f.puts Oj.dump(res)}
    return res
  end

  # this could also set the value back to the original one, but meh...
  # receives an array of {ac_id: x, value: 42} hashes
  def run_with(params)
    params.each do |arg|
      ac = attribute_constraints.where(id: arg[:ac_id]).first
      ac.update_attributes(value: arg[:value]) unless ac.nil?
    end
    run()
  end

  def executable?
    measurable.executable_on?(target_ontology)
  end

  def translate_this
    return measurable.first_untranslated_pattern(target_ontology)
  end

  def name
    "'#{measurable.name}' on '#{repository.name}'"
  end

  def target_ontology
    repository.ontology
  end

  def execute_query(q)
    repository.results_for_query(q)
  end

  def query(pattern, aggregations = [])
    repository.query_creator_class.new(pattern, aggregations, self).query_string
  end

  def queries()
    measurable.queries(self)
  end

  def parameters()
    measurable.parameters(self)
  end
end