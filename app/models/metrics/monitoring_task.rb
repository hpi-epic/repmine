class MonitoringTask < ActiveRecord::Base
  attr_accessible :repository_id, :measurable_id

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

  def enqueue
    job = QueryExecutionJob.new(:monitoring_task_id => id)
    Delayed::Job.enqueue(job, :queue => repository.query_queue)
  end

  def run(job = nil)
    repository.job = job
    res = measurable.run_on_repository(repository)
    repository.job = nil
    File.open(result_file, "wb"){|f| f.puts Oj.dump(res)}
  end

  def executable?
    measurable.executable_on?(repository)
  end

  def translate_this
    if measurable.is_a?(Pattern)
      return measurable
    else
      return measurable.first_unexecutable_pattern(repository)
    end
  end

  def results_file(ending)
    return Rails.root.join("public","data","#{filename}.#{ending}").to_s
  end

  def filename
    "#{measurable.class.name}_#{measurable_id}_repo_#{repository.id}"
  end

  def fancy_name(thingy)
    return thingy.underscore.gsub(/\s/, "_")
  end

  def result_file
    results_file("json")
  end

  def results
    return Oj.load(File.open(result_file).read)
  end

  def queries
    measurable.queries_on(repository)
  end
end