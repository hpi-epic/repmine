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
  
  def fancy_rdf_string
    @node = Node.find(params[:node_id])
    @te = @node.type_expression
    render :layout => false
  end
  
  def translation_node
    render :json => {}
  end
end