class MeasurablesController < ApplicationController

  def index
    if Pattern.count == 0
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
      @measurable_groups = Pattern.grouped.merge(Metric.grouped)
      @ontology_groups = Ontology.grouped
      @repositories = Repository.all
    end
    @title = "Pattern & Metric Overview"
  end

  def destroy
    Measurable.find(params[:id]).destroy
    redirect_to measurables_path
  end

  def monitor
    task_ids = MonitoringTask.create_multiple(params[:measurables], params[:repository_id])
    redirect_to check_monitoring_tasks_path(:task_ids => task_ids)
  end

end