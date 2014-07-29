class RelationConstraintsController < ApplicationController

  layout false
  
  before_filter :get_pattern
  
  def get_pattern
    @pattern = Pattern.find(params[:pattern_id])
  end
    
  def create
    source = Node.find(params[:source_id])
    target = Node.find(params[:target_id])
    @relation_constraint = source.create_relation_constraint_with_target!(target)
    @possible_relations = source.possible_relations_to(target, params[:source_type], params[:target_type])
    render :show
  end
  
  def show
    @relation_constraint = RelationConstraint.find(params[:id])
  end
  
  def update
    @relation_constraint = RelationConstraint.find(params[:id])
    respond_to do |format|
      if @relation_constraint.update_attributes(params[:relation_constraint])
        format.json { head :ok }
      else
        format.json { render json: @relation_constraint.errors, status: :unprocessable_entity }
      end
    end
  end
  
end
