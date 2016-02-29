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
    FileUtils.rm_rf(results_file("yml"))
    FileUtils.rm_rf(results_file("csv"))
  end

  def has_latest_results?
    return File.exist?(results_file("yml")) && File.exist?(results_file("csv"))
  end

  def enqueue
    job = QueryExecutionJob.new(:monitoring_task_id => id)
    Delayed::Job.enqueue(job, :queue => repository.query_queue)
  end

  def run(job = nil)
    repository.job = job
    res, csv = measurable.run_on_repository(repository)
    repository.job = nil
    File.open(results_file("yml"), "w+"){|f| f.puts res.to_yaml}
    File.open(results_file("csv"), "w+"){|f| f.puts csv}
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

  def short_name
    "'#{measurable.name}' on '#{repository.name}'"
  end

  def results_file(ending)
    return Rails.root.join("public","data","#{filename}.#{ending}").to_s
  end

  def filename
    "#{measurable.class.name}_#{measurable_id}_repo_#{repository.id}"
  end

  def csv_result
    return File.open(results_file("csv")).read
  end

  def pretty_csv_name
    return "#{fancy_name(measurable.name)}-on-#{fancy_name(repository.name)}.csv"
  end

  def fancy_name(thingy)
    return thingy.underscore.gsub(/\s/, "_")
  end

  def results
    return YAML::load(File.open(results_file("yml")).read)
  end
end