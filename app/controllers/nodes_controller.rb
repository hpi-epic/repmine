class NodesController < ApplicationController

  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end
  
  def create
    @node = @pattern.nodes.create!
    @type_hierarchy = @pattern.type_hierarchy
    render :show, :layout => false
  end
  
  def show
    @node = Node.find(params[:id])
    @type_hierarchy = @pattern.type_hierarchy
    render :layout => false
  end
  
end