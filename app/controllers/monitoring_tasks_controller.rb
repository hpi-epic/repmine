class MonitoringTasksController < ApplicationController
  
  def index
    @repos_with_tasks = Repository.find(MonitoringTask.pluck(:repository_id).uniq)
    @query_jobs = {}
    @repos_with_tasks.collect{|repo| repo.query_jobs}.flatten.each do |qj|
      pattern = Pattern.find(qj.payload_object.pattern_id)
      @query_jobs[qj.id] = pattern.name
    end
  end
  
  def csv_results
    mt = MonitoringTask.find(params[:monitoring_task_id])
    send_data(mt.csv_result, :type => 'text/csv; charset=utf-8; header=present', :filename => mt.pretty_csv_name)
  end
  
  def run
    @task = MonitoringTask.find(params[:monitoring_task_id])
    @task.run
    redirect_to monitoring_tasks_path, :notice => "Enqueued new query!"
  end
  
  def show_results
    @task = MonitoringTask.find(params[:monitoring_task_id])
    @results = @task.results[:data]
    @headers = @task.results[:headers]
  end
  
end
