class AttributeConstraintsController < ApplicationController
  
  layout false
  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end

  def create
    @node = Node.find(params[:node_id])
    @ac = AttributeConstraint.create(:node => @node)
    @possible_attributes = @ac.possible_attributes(params[:rdf_type])
    render :show
  end
  
  def show
    @ac = AttributeConstraint.find(params[:id])
    @possible_attributes ||= @ac.possible_attributes()
  end
  
  def update
    @ac = AttributeConstraint.find(params[:id])
    respond_to do |format|
      if @ac.update_attributes(params[:attribute_constraint])
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @ac.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @ac = AttributeConstraint.find(params[:id])
    respond_to do |format|
      if @ac.destroy
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @ac.errors, status: :unprocessable_entity }
      end
    end
  end
  
end
