class AttributeConstraintsController < ApplicationController
  
  layout false
  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end

  def create
    @node = Node.find(params[:node_id])
    @attribute_constraint = AttributeConstraint.create(:node => @node)
    @possible_attributes = @node.possible_attributes(params[:rdf_type])
    render :show
  end
  
  def show
    @attribute_constraint = AttributeConstraint.find(params[:id])
  end
  
  def update
    @attribute_constraint = AttributeConstraint.find(params[:id])
    respond_to do |format|
      if @attribute_constraint.update_attributes(params[:attribute_constraint])
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @attribute_constraint.errors, status: :unprocessable_entity }
      end
    end
  end
  
end
