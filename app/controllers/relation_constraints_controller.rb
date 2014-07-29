class RelationConstraintsController < ApplicationController

  layout false
  
  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end
  
  # only one relation constraint in one direction allowed between two nodes. This is a UI restriction, though...
  def create
    @rc = RelationConstraint.find_or_create_by_source_id_and_target_id(params[:source_id], params[:target_id])
    @possible_relations = @rc.possible_relations(params[:source_type], params[:target_type])
    render :show
  end
  
  def show
    @rc = RelationConstraint.find(params[:id])
  end
  
  def update
    @rc = RelationConstraint.find(params[:id])
    respond_to do |format|
      if @rc.update_attributes(params[:relation_constraint])
        format.json { head :ok }
      else
        format.json { render json: @rc.errors, status: :unprocessable_entity }
      end
    end
  end
  
end
