class RelationConstraintsController < ApplicationController

  layout false
  
  def create
    source = Node.find(params[:source_id])
    target = Node.find(params[:target_id])
    @relation_constraint = source.create_relations_constraint_with_target!(target)
    @possible_relations = @relation_constraint.possible_relations()
    render :show
  end
  
  def show
    @relation_constraint = RelationConstraint.find(params[:id])
  end
end
