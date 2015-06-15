class AggregationsController < ApplicationController
  
  layout false
    
  def create
    @pattern = Pattern.find(params[:pattern_id])
    @pattern_element = PatternElement.find(params[:pattern_element_id])
    if @pattern_element.aggregation.nil?
      @pattern_element.create_aggregation(:operation => params[:operation])
    else
      @pattern_element.aggregation.update_attributes(:operation => params[:operation])
    end
    
    render :partial => "aggregations/show", :locals => {:aggregation => @pattern_element.aggregation}
  end
  
  def destroy
    Aggregation.destroy(params[:id])
    render :json => {}
  end
  
end