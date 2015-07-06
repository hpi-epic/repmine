class MonitoringTasksController < ApplicationController
  
  def index
    @repos_with_tasks = Repository.find(MonitoringTask.pluck(:repository_id).uniq)
    @query_jobs = {}
    @repos_with_tasks.collect{|repo| repo.query_jobs}.flatten.each do |qj|
      @query_jobs[qj.id] = qj.payload_object.pattern.name
    end
    @new_tasks = params[:task_ids] || []
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
  
  def destroy
    @task = MonitoringTask.find(params[:id])
    @task.destroy
    redirect_to monitoring_tasks_path, :notice => "Stopped monitoring pattern on repository."
  end
  
  def check
    tasks = MonitoringTask.find(params[:task_ids])
    
    tasks.each do |task|
      unless task.executable?
        redirect_to(pattern_translate_path(task.pattern, task.repository.ontology), :notice => "Please translate the pattern, first!") and return
      end
    end
    
    redirect_to monitoring_tasks_path(:new_tasks => params[:task_ids]), :notice => "Successfully added monitoring tasks!"
  end
  
end
