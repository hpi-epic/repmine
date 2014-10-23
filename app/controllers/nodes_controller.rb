class NodesController < ApplicationController
  
  # these are always just embedded, no need for a layout
  layout false
  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end
  
  def create
    @node = @pattern.create_node!
    if params[:element_type] == "Node"
      @node.equivalent_to = Node.find(params[:element_id])
      @node.save
    else
      flash[:notice] = "Next time, please select the equivalent input node before creating a new one. Thank you!"
    end

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
      rdf_type = params[:node].delete(:rdf_type)
      @node.rdf_type = rdf_type
      if @node.update_attributes(params[:node])
        @node.type_expression.save
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @node = Node.find(params[:id])
    @node.destroy
    render :json => {}
  end
  
  def fancy_rdf_string
    @node = Node.find(params[:node_id])
    @te = @node.type_expression
  end
end