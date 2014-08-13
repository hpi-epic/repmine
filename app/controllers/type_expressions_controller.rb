class TypeExpressionsController < ApplicationController
  
  before_filter :set_inst_vars, :except => [:update]
  
  def add_below
    @te.children.create(:rdf_type => @te.operator? ? "" : nil)
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end
  
  def add_same_level
    @new_te = @te.parent.children.create(:rdf_type => "") unless @te.operator?
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end
  
  def delete
    @te.destroy unless @te.is_root? || (@te.depth == 1 && @te.root.children.size == 1)
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end  
  
  def get_locals()
    {:type_expression => @node.type_expression, :type_hierarchy => @pattern.type_hierarchy, :pattern => @pattern, :node => @node}
  end
  
  def update
    @te = TypeExpression.find(params[:id])    
    respond_to do |format|
      if @te.update_attributes(params[:type_expression])
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @te.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def set_inst_vars
    @te = TypeExpression.find(params[:type_expression_id] || params[:id])
    @pattern = Pattern.find(params[:pattern_id])
    @node = Node.find(params[:node_id])
  end
end
