class MonitoringTasksController < ApplicationController

  def index
    @repos_with_tasks = Repository.find(MonitoringTask.pluck(:repository_id).uniq)
    if @repos_with_tasks.empty?
      redirect_to measurables_path, :notice => "Please select patterns and metrics that you want to monitor!"
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
    name = @task.name
    @task.destroy
    redirect_to monitoring_tasks_path, :notice => "Deleted Monitoring task '#{name}'."
  end

  def parameters
    @task = MonitoringTask.find(params[:monitoring_task_id])
  end

  def run
    @task = MonitoringTask.find(params[:monitoring_task_id])
    render json: @task.run_with(params[:task_parameters] || [])
  end

end
