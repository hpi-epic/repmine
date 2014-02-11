class NodesController < ApplicationController
  
  def show
    @graph = Graph.find(params[:graph_id])
    node = graph.get_node(params[:node_url])
  end
  
  def add_linked_node
    
  end
  
end