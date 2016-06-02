class RelationConstraintsController < ApplicationController

  layout false

  def create
    @rc = RelationConstraint.create(:source_id => params[:source_id], :target_id => params[:target_id])
    @possible_relations = @rc.possible_relations()
    render :show
  end

  def show
    @rc = RelationConstraint.find(params[:id])
    @possible_relations ||= @rc.possible_relations()
  end

  def update
    @rc = RelationConstraint.find(params[:id])
    respond_to do |format|
      if @rc.update_attributes(params[:relation_constraint])
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @rc.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @rc = RelationConstraint.find(params[:id])
    @rc.destroy
    render :json => {}
  end

  def static
    @rc = RelationConstraint.find(params[:relation_constraint_id])
  end

end
