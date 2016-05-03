class NodesController < ApplicationController

  # these are always just embedded, no need for a layout
  layout false

  def create
    @pattern = Pattern.find(params[:pattern_id])
    @ontology = Ontology.find(params[:ontology_id])
    default_type = @ontology.type_hierarchy.first
    @node = @pattern.create_node!(@ontology, default_type.nil? ? "" : default_type.url)
    render :show
  end

  def show
    @node = Node.find(params[:id])
  end

  def update
    @node = Node.find(params[:id])
    respond_to do |format|
      if @node.update_attributes(params[:node])
        format.json { render json: {}, status => :ok }
      else
        flash[:error] = "Could not save node! #{@node.errors.full_messages.join("! ")}"
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @node = Node.find(params[:id])
    @node.destroy
    render :json => {}
  end

end
