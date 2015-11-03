class OntologiesController < ApplicationController

  # GET /ontologies
  # GET /ontologies.json
  def index
    @ontologies = Ontology.all
    if @ontologies.empty?
      flash[:notice] = "No ontologies present. Create one or extract one from a repository."
      redirect_to new_ontology_path
    end
    @title = "Ontology overview"
  end

  # GET /ontologies/new
  # GET /ontologies/new.json
  def new
    @ontology = Ontology.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ontology }
    end
  end

  # GET /ontologies/1/edit
  def edit
    @ontology = Ontology.find(params[:id])
    @title = "Ontology '#{@ontology.short_name}'"
  end

  # POST /ontologies
  # POST /ontologies.json
  def create
    @ontology = Ontology.new(params[:ontology])
    if @ontology.save
      redirect_to ontologies_path, notice: 'Ontology was successfully created.'
    else
      flash[:error] = 'Could not create ontology. ' + @ontology.errors.full_messages.join(", ")
      render :new
    end
  end

  # PUT /ontologies/1
  # PUT /ontologies/1.json
  def update
    @ontology = Ontology.find(params[:id])

    respond_to do |format|
      if @ontology.update_attributes(params[:ontology])
        format.html { redirect_to @ontology, notice: 'Ontology was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json { render json: @ontology.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ontologies/1
  # DELETE /ontologies/1.json
  def destroy
    @ontology = Ontology.find(params[:id])
    @ontology.destroy

    respond_to do |format|
      format.html { redirect_to ontologies_url }
      format.json { head :no_content }
    end
  end

  def autocomplete_ontology_group
    groups = Ontology.pluck(:group).uniq.compact.select{|gr| gr.downcase.match(params[:term].downcase)}
    render :json => groups.collect{|group| {:value => group, :label => group}}
  end
end
