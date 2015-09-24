class ServicesController < ApplicationController

  def index
    @services = Service.all
    if @services.empty?
      redirect_to new_service_path
    end
  end

  def new
    @service = Service.new
  end

  def create
    Service.create(params[:service])
    redirect_to services_path
  end

  def show
    @service = Service.find(params[:id])
  end

  def edit
    @service = Service.find(params[:id])
  end
end