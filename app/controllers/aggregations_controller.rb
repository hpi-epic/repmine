class AggregationsController < ApplicationController

  layout false

  def create
    mn = MetricNode.find(params[:metric_node_id])
    aggregation = mn.aggregations.where(pattern_element_id: params[:pattern_element_id], column_name: params[:column_name]).first_or_create!
    aggregation.update_attributes(operation: params[:operation], alias_name: params[:alias_name], distinct: params[:distinct])
    render partial: "aggregations/show", locals: {aggregation: aggregation}
  end

  def destroy
    Aggregation.destroy(params[:id])
    render json: {}
  end
end