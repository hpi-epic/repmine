class NodesController < ApplicationController
  
  # these are always just embedded, no need for a layout
  layout false

  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end
  
  def create
    @node = @pattern.nodes.create!
    @type_hierarchy = @pattern.type_hierarchy
    render :show
  end
  
  def show
    @node = Node.find(params[:id])
    @type_hierarchy = @pattern.type_hierarchy
  end
  
  def update
    @node = Node.find(params[:id])
    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.json { head :ok }
      else
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end
  
end