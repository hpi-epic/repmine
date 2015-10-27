class NodesController < ApplicationController

  # these are always just embedded, no need for a layout
  layout false

  def create
    @pattern = Pattern.find(params[:pattern_id])
    @node = @pattern.create_node!(Ontology.find(params[:ontology_id]))
    render :show
  end

  def show
    @node = Node.find(params[:id])
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
