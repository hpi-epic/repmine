class AttributeConstraintsController < ApplicationController

  layout false

  def create
    @node = Node.find(params[:node_id])
    if params[:attribute_constraint].nil?
      @ac = AttributeConstraint.create({:node => @node})
      render :show
    else
      AttributeConstraint.create({:node => @node}.merge(params[:attribute_constraint]))
      redirect_to(:back)
    end
  end

  def show
    @ac = AttributeConstraint.find(params[:id])
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
      format.html{redirect_to(:back)}
    end
  end

  def static
    @ac = AttributeConstraint.find(params[:attribute_constraint_id])
  end

end
