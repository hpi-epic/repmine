class AttributeConstraintsController < ApplicationController
  
  layout false
  
  def create
    node = Node.find(params[:node_id])
    @attribute_constraint = AttributeConstraint.create(:node => source)
    @possible_attributes = node.possible_attributes()
    render :show
  end
  
  def show
    @attribute_constraint = AttributeConstraint.find(params[:id])
  end
  
end
