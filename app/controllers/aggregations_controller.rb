class AggregationsController < ApplicationController

  layout false

  def create
    mn = MetricNode.find(params[:metric_node_id])
    aggregation = mn.aggregations.where(pattern_element_id: params[:pattern_element_id], column_name: params[:column_name]).first_or_initialize
    if aggregation.update_attributes(operation: params[:operation], alias_name: params[:alias_name], distinct: params[:distinct])
      render partial: "aggregations/show", locals: {aggregation: aggregation}
    else
      flash[:error] = "Could not save Aggregation! <br/> #{aggregation.errors.full_messages.join("<br />")}"
      render json: {}, :status => :unprocessable_entity
    end
  end

  def destroy
    Aggregation.destroy(params[:id])
    head :no_content
  end
end