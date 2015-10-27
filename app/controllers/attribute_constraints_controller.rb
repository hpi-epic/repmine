class AttributeConstraintsController < ApplicationController

  layout false

  def create
    @node = Node.find(params[:node_id])
    @ac = AttributeConstraint.create(:node => @node)
    @possible = @ac.possible_attributes(params[:rdf_type])
    render :show
  end

  def show
    @ac = AttributeConstraint.find(params[:id])
    @possible ||= @ac.possible_attributes()
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

  def magic
    @ac = AttributeConstraint.find(params[:attribute_constraint_id])
    render :partial => "form"
  end

  def destroy
    @ac = AttributeConstraint.find(params[:id])
    respond_to do |format|
      @ac.destroy
      format.js
    end
  end

  def static
    @ac = AttributeConstraint.find(params[:attribute_constraint_id])
  end

end
