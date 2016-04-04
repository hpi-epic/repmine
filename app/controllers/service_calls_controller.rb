class ServiceCallsController < ApplicationController

  def show
    @service_call = ServiceCall.find(params[:id])
  end

  def run
    @service_call = ServiceCall.find(params[:service_call_id])
    @service_call.invoke
  end

end