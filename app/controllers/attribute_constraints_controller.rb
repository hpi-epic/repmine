class AttributeConstraintsController < ApplicationController
  
  layout false
  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end

  def create
    node = Node.find(params[:node_id])
    @attribute_constraint = AttributeConstraint.create(:node => node)
    @possible_attributes = node.possible_attributes(params[:rdf_type])
    render :show
  end
  
  def show
    @attribute_constraint = AttributeConstraint.find(params[:id])
  end
  
end
