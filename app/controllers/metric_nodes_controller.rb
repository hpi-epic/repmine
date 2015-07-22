class MetricNodesController < ApplicationController

  layout :false
  
  def update
    mn = MetricNode.find(params[:id])
    mn.update_attributes(params[:metric_node])
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end
  
  def destroy
    MetricNode.find(params[:id]).destroy
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end
  
  def show
    node = MetricNode.find(params[:id])
    render :partial => "metric_nodes/show", :layout => false, :locals => {:node => node}
  end
  
end
