class TypeExpressionsController < ApplicationController

  before_filter :set_inst_vars, :except => [:update, :fancy_string]

  def add_below
    @te.children.create(:rdf_type => params[:operator] == "true" ? nil : "")
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end

  def add_same_level
    @new_te = @te.parent.children.create(:rdf_type => params[:operator] == "true" ? nil : "")
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end

  def delete
    @te.destroy unless @te.is_root? || (@te.depth == 1 && @te.root.children.size == 1)
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end

  def show
    render :layout => false, :partial => "type_expressions/show", :locals => get_locals
  end

  def get_locals()
    {:type_expression => @node.type_expression, :type_hierarchy => @node.type_hierarchy, :node => @node}
  end

  def update
    @te = get_type_expression
    respond_to do |format|
      if @te.update_attributes(params[:type_expression])
        format.json { render json: {}, status => :ok }
      else
        format.json { render json: @te.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_inst_vars
    @node = Node.find(params[:node_id])
    @te = begin
      get_type_expression
    rescue Exception => e
      @node.type_expression
    end
  end

  def get_type_expression
    TypeExpression.find(params[:type_expression_id] || params[:id])
  end
end
