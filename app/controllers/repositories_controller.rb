class RepositoriesController < ApplicationController

  # GET /repositories
  # GET /repositories.json
  def index
    @repositories = Repository.all
    flash[:notice] = "No repositories present. Please create a new one!" if @repositories.empty?
    @title = "Repository overview"
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json =>  @repositories }
    end
  end

  # GET /repositories/1
  # GET /repositories/1.json
  def show
    @repository = Repository.find(params[:id])
    @stats = [["Item Type", "Occurrences in Repository"]]
    begin
      @stats.concat(@repository.type_statistics)
    rescue Exception => e
      flash[:error] = e.message
    end

    @job = @repository.ontology_creation_job
    @title = "Repository '#{@repository.name}'"

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json =>  @repository }
    end
  end

  # GET /repositories/new
  # GET /repositories/new.json
  def new
    if params[:type].nil?
      redirect_to repositories_path
      return
    end

    @repository = Repository.for_type(params[:type])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json =>  @repository }
    end
  end

  # GET /repositories/1/edit
  def edit
    @repository = Repository.find(params[:id])
  end

  # POST /repositories
  # POST /repositories.json
  def create
    @repository = Repository.for_type(params[:repository].delete(:type), params[:repository])
    respond_to do |format|
      if @repository.save
        format.html { redirect_to @repository, :notice => 'Repository was successfully created.' }
        format.json { render :json =>  @repository, :status => :created, :location => @repository }
      else
        format.html { render :new }
        format.json { render :json =>  @repository.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /repositories/1
  # PUT /repositories/1.json
  def update
    @repository = Repository.find(params[:id])
    params[:repository].delete("type")

    respond_to do |format|
      if @repository.update_attributes(params[:repository])
        format.html { redirect_to @repository, :notice => 'Graph was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json { render :json =>  @repository.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /repositories/1
  # DELETE /repositories/1.json
  def destroy
    @repository = Repository.find(params[:id])
    @repository.destroy

    respond_to do |format|
      format.html { redirect_to repositories_url }
      format.json { head :no_content }
    end
  end

  def extract_schema
    @repository = Repository.find(params[:repository_id])
    @repository.extract_ontology!(true)
    redirect_to @repository, :notice => "Started analyzing the repository in a background thread."
  end

  def prepare_service
    service = Service.find(params[:service_id])
    repository = Repository.find(params[:repository_id])
    service_call = ServiceCall.for_service_and_repository(service, repository)
    redirect_to service_call_path(service_call)
  end
end
