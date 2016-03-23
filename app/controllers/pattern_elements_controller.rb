class PatternElementsController < ApplicationController

  def set_name
    @pe = PatternElement.find(params[:pattern_element_id])
    if @pe.update_attributes(name: params[:value])
      render :nothing => true, :status => 200, :content_type => 'text/html'
    else
      render :text => @pe.errors.full_messages.join(", "), :status => 400, :content_type => 'text/html'
    end
  end

end