class MetricsController < ApplicationController
  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'

  def create
    @metric = Metric.new
    @metric.save(validate: false)
    redirect_to metric_path(@metric)
  end

  def show
    @metric = Metric.find(params[:id])
    @measurable_groups = Metric.grouped([@metric]).merge(Pattern.grouped){|key, val1, val2| val1 + val2}
    @existing_connections = []
    @metric.metric_nodes.each do |node|
      node.children.each do |child|
        @existing_connections << {:source => node.id, :target => child.id}
      end
    end
    @title = @metric.name.blank? ? "New metric" : "Metric '#{@metric.name}'"
  end

  def update
    metric = Metric.find(params[:id])
    if metric.update_attributes(params[:metric])
      flash[:notice] = "Successfully saved metric!"
      render json: {}
    else
      flash[:error] = "Could not save metric! <br/> #{metric.errors.full_messages.join("<br />")}"
      render json: {}, :status => :unprocessable_entity
    end
  end

  def destroy
    Metric.find(params[:id]).destroy
    redirect_to metrics_path
  end

  def create_connection
    source = MetricNode.find(params[:source_id])
    target = MetricNode.find(params[:target_id])
    target.parent = source
    target.save(validate: false )
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end

  def destroy_connection
    begin
      source = MetricNode.find(params[:source_id])
      target = MetricNode.find(params[:target_id])
      target.parent = nil
      target.save
    rescue Exception => e
    end
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end

  def index
    @metrics_groups = Metric.grouped
    flash[:info] = "No metrics available! Please create a new one." if @metrics_groups.empty?
    @repositories = Repository.includes(:ontology).where(:ontologies => {:does_exist => true})
    @title = "Metric overview"
  end

  def monitor
    task_ids = MonitoringTask.create_multiple(params[:metrics], params[:repository_id])
    redirect_to check_monitoring_tasks_path(:task_ids => task_ids)
  end

  def download_csv
    repository = Repository.find(params[:repository_id])
    metric = Metric.find(params[:metrics].first)
    metric.calculate(repository)
    send_data(
      File.open(metric.metrics_path("csv", repository)).read,
      :type => 'text/csv; charset=utf-8; header=present',
      :filename => metric.fancy_metric_file_name(repository)
    )
  end

  def create_node
    metric = Metric.find(params[:metric_id])
    measurable = Measurable.find(params[:pattern_id])
    node = metric.create_node(measurable)
    render :partial => "metric_nodes/show", :layout => false, :locals => {:node => node}
  end

  def create_operator
    metric = Metric.find(params[:metric_id])
    node = MetricOperatorNode.create(:operator_cd => params[:operator])
    metric.metric_nodes << node
    render :partial => "metric_nodes/show", :layout => false, :locals => {:node => node}
  end
end