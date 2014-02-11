require 'rdf/rdfxml'

class ExtractionDescriptionsController < ApplicationController

  def index
    @extraction_descriptions = ExtractionDescription.all
    respond_to do |format|
      format.html
    end
  end
  
  def graphical_view
    @ed = ExtractionDescription.find(params[:extraction_description_id])
    nodes = NodeMapping.where(:extraction_description_id => @ed.id, :ignore => false)
    @groups = {}
    nodes.each do |node|
      @groups[node.element_type] ||= []
      @groups[node.element_type] << node
    end
    puts @groups.keys.to_yaml
  end
  
  def show
    begin
      @ed = ExtractionDescription.find(params[:id])
    rescue Exception => e
      redirect_to(extraction_descriptions_path)
      return
    end
    
    # fuck you, development mode...
    AliasAttributeMapping
    RelationMapping
    AttributeMapping
    NodeMapping
    
    respond_to do |format|
      format.html
      format.rdf{
        rdf_string = @ed.rdf_xml()
        send_data(rdf_string, :type => "application/rdf+xml; charset=utf-8; header=present", :filename => "#{@ed.name.underscore}_extraction.rdf")
      }
    end
  end
  
  def new
    @ed = ExtractionDescription.new
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @ed = ExtractionDescription.new(params[:extraction_description])
    if @ed.valid?
      root_mapping = @ed.parse_descriptions!
      @ed.save!
      root_mapping.extraction_description = @ed
      root_mapping.save!
    end
    
    if @ed.save!
      redirect_to(@ed, :notice => 'Succesfully created mapping!')
    else
      flash[:alert] = "Extraction Description could not be saved! #{@ed.errors.full_messages.join(", ")}"
      render :action => "new"
    end
  end
  
  def destroy
    @ed = ExtractionDescription.find(params[:id])
    @ed.destroy
    redirect_to(extraction_descriptions_path)
  end
  
  def ontology_proposal
    @ed = ExtractionDescription.find(params[:extraction_description_id])
    respond_to do |format|
      format.html
      format.rdf{
        rdf_string = @ed.ontology_proposal_rdf()
        send_data(rdf_string, :type => "application/rdf+xml; charset=utf-8; header=present", :filename => "#{@ed.name.underscore}.rdf")
      }
    end
  end
  
end
