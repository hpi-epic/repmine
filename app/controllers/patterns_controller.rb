class PatternsController < ApplicationController

  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'
  
  def new
    @pattern = Pattern.new
  end
  
  def show
    @pattern = Pattern.find(params[:id])
    # little performance tweak, only load the hierarchy, if we have nodes that go with it
    @type_hierarchy = @pattern.nodes.empty? ? nil : @pattern.type_hierarchy
    load_attributes_and_constraints!
  end
  
  def translate
    @pattern = Pattern.find(params[:pattern_id])
    @offset = @pattern.nodes.collect{|n| n.y}.max
    load_attributes_and_constraints!(true)    
  end
    
  def create
    @pattern = Pattern.new(params[:pattern])
    respond_to do |format|
      if @pattern.save
        @pattern.initialize_repository!
        flash[:notice] = 'Pattern was successfully created.'
        format.html { redirect_to @pattern}
      else
        flash[:error] = 'Could not create pattern. ' + @pattern.errors.full_messages.join(", ")
        format.html {render action: "new"}
      end
    end
  end
  
  def index
    @patterns = Pattern.all
    if @patterns.empty?
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
      @repositories = Repository.all_that_have_an_ontology
    end
  end
  
  def update
    @pattern = Pattern.find(params[:id])
    respond_to do |format|
      if @pattern.update_attributes(params[:pattern])
        @pattern.touch
        format.json { render json: {:message => "Pattern successfully saved!"}, status => :ok}
      else
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @pattern = Pattern.find(params[:id])
    qn = @pattern.name
    @pattern.destroy
    flash[:notice] = "Destroyed Pattern '#{qn}'"
    redirect_to patterns_path
  end
    
  def reset
    @pattern = Pattern.find(params[:pattern_id])
    @pattern.reset!
    flash[:notice] = "Resetted Pattern to state of: #{@pattern.updated_at}"    
    redirect_to pattern_path(@pattern)
  end
  
  def missing_concepts
    @pattern = Pattern.find(params[:pattern_id])
    @repository = Repository.find(params[:repository_id])
    @matching_error = nil
    @missing_concepts = begin
      @pattern.unmatched_concepts(@repository)
    rescue OntologyMatcher::MatchingError => e
      @matching_error = e.message
      nil
    end
    
    render :layout => false 
  end

  # callbacks from here on
  def possible_relations
    @pattern = Pattern.find(params[:pattern_id])
    render :json => @pattern.possible_relations_between(params[:source], params[:target])
  end
  
  def possible_attributes
    @pattern = Pattern.find(params[:pattern_id])
    render :json => @pattern.possible_attributes_for(params[:node_class])
  end
  
  private 
  
  def load_attributes_and_constraints!(static = false)
    # load existing relation constraints
    @relations = @pattern.nodes.collect do |node|
      node.source_relation_constraints.collect do |src| 
        {:source => node.id, :target => src.target_id, :url => static ? pattern_relation_constraint_static_path(@pattern, src) : pattern_relation_constraint_path(@pattern, src)}
      end
    end.flatten
    
    # and attribute constraints, as well
    @attributes = {}
    @pattern.nodes.each do |node|
      node.attribute_constraints.each do |nac|
        @attributes[node.id] ||= []
        @attributes[node.id] << if static 
          pattern_attribute_constraint_static_path(@pattern, nac)          
        else
          pattern_attribute_constraint_path(@pattern, nac)
        end
      end
    end
  end
end
