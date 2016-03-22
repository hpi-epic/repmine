class MonitoringTasksController < ApplicationController

  def index
    @repos_with_tasks = Repository.find(MonitoringTask.pluck(:repository_id).uniq)
    if @repos_with_tasks.empty?
      redirect_to patterns_path, :notice => "Please select patterns and metrics that you want to monitor!"
    else
      @query_jobs = {}
      @repos_with_tasks.collect{|repo| repo.query_jobs}.flatten.each do |qj|
        mt = MonitoringTask.includes(:measurable).find(qj.payload_object.monitoring_task_id)
        @query_jobs[qj.id] = mt.measurable.name
      end
      @new_tasks = params[:task_ids] || []
    end
    @title = "Monitoring Task Overview"
  end

  def results
    @task = MonitoringTask.find(params[:monitoring_task_id])
    if @task.has_latest_results?
      @results = @task.results
      @headers = @results.collect{|res| res.keys}.flatten.uniq
      @title = "Results for '#{@task.measurable.name}' on #{@task.repository.name}"
      @task.enqueue
    else
      @task.enqueue
      redirect_to monitoring_tasks_path, notice: "Results are being generate in the background."
    end
  end

  def query
    @task = MonitoringTask.find(params[:monitoring_task_id])
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
        redirect_to(pattern_prepare_translation_path(task.translate_this, task.repository.ontology), :notice => "Please translate the pattern, first!") and return
      end
    end
    redirect_to monitoring_tasks_path(:new_tasks => params[:task_ids]), :notice => "Successfully added monitoring tasks!"
  end

end
