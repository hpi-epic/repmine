# Delayed Job with progress extension to create an ontology for the repository
class QueryExecutionJob < ProgressJob::Base
  
  attr_accessor :monitoring_task_id
  
  # not nice, but works...
  def initialize(*args)
    super()
    @progress_max = args[0][:progress_max] || 100
    @monitoring_task_id = args[0][:monitoring_task_id]
  end
  
  def perform
    mt = MonitoringTask.find(monitoring_task_id)
    mt.run(self)
  end
  
  def destroy_failed_jobs?
    true
  end
end