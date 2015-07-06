class MetricsController < ApplicationController
  
  def create
    @metric = Metric.create
    redirect_to metric_path(@metric)
  end
  
  def show
    @pattern_groups = Pattern.grouped(true)
    @metric = Metric.find(params[:id])
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
    metric.update_attributes(params[:metric])
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end
  
  def create_connection
    source = MetricNode.find(params[:source_id])
    target = MetricNode.find(params[:target_id])
    target.parent = source
    target.save
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
    @metrics = Metric.all
    @repositories = Repository.all()
    @title = "Metric overview"
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
    pattern = Pattern.find(params[:pattern_id])
    
    @node = metric.metric_nodes.create(:pattern_id => pattern.id)
    render :partial => "metric_nodes/node", :layout => false, :locals => {:node => @node}
  end
  
  def create_operator
    metric = Metric.find(params[:metric_id])
    @node = metric.metric_nodes.create(:operator_cd => params[:operator])
    render :partial => "metric_nodes/operator_node", :layout => false, :locals => {:node => @node}
  end
  
end
