class MeasurablesController < ApplicationController

  def index
    excluded = ServiceCall.pluck(:pattern_id)
    @measurable_groups = Pattern.grouped(excluded).merge(Metric.grouped){|key, patterns, metrics| patterns+metrics}

    if @measurable_groups.empty?
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
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
    redirect_to monitoring_tasks_path, :notice => "Successfully added #{task_ids.size} monitoring tasks!"
  end
end