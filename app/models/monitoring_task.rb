class MonitoringTask < ActiveRecord::Base
  attr_accessible :repository_id, :pattern_id
  
  belongs_to :repository
  belongs_to :pattern
  
  def has_latest_results?
    return File.exist?(results_file("yml")) && File.exist?(results_file("csv"))
  end
  
  def run
    job = QueryExecutionJob.new(:repository_id => repository.id, :pattern_id => pattern.id)
    Delayed::Job.enqueue(job, :queue => repository.query_queue)
  end
  
  def results_file(ending)
    return Rails.root.join("public","data","pattern_#{pattern.id}_repo_#{self.id}.#{ending}").to_s
  end
  
  def csv_result
    return File.open(results_file("csv")).read
  end
  
  def pretty_csv_name
    return "#{pattern.name.underscore}-on-#{repository.name.underscore}.csv"
  end
  
  def results
    return YAML::load(File.open(results_file("yml")).read)
  end
end
