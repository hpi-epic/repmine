class MonitoringTask < ActiveRecord::Base
  attr_accessible :repository_id, :measurable_id
  
  belongs_to :repository
  belongs_to :measurable
  
  def self.create_multiple(measurable_ids, repository_id)
    return measurable_ids.collect do |m_id|
      self.where(:measurable_id => m_id,  :repository_id => repository_id).first_or_create!.id
    end.uniq
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
    return "#{measurable.name.underscore}-on-#{repository.name.underscore}.csv"
  end
  
  def results
    return YAML::load(File.open(results_file("yml")).read)
  end
end