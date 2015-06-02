class PatternsController < ApplicationController

  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'

  def new
    @pattern = Pattern.new
  end

  def show
    @pattern = Pattern.find(params[:id])
    # little performance tweak, only load the hierarchy, if we have nodes that go with it
    @type_hierarchy = @pattern.nodes.empty? ? nil : @pattern.ontology.type_hierarchy
    @attributes, @relations = load_attributes_and_constraints!(@pattern)
  end
  
  def translate
    @source_pattern = Pattern.find(params[:pattern_id])
    @source_pattern.auto_layout!
    @source_attributes, @source_relations = load_attributes_and_constraints!(@source_pattern, true)
    @offset = @source_pattern.node_offset

    @ontology = Ontology.find(params[:ontology_id])
    @target_pattern = TranslationPattern.for_pattern_and_ontology(@source_pattern, @ontology)
    
    @type_hierarchy = @target_pattern.nodes.empty? ? nil : @target_pattern.ontology.type_hierarchy
    @target_attributes, @target_relations = load_attributes_and_constraints!(@target_pattern)
    @matched_elements = @source_pattern.matched_elements(@ontology).collect{|me| me.id.to_s}
  end

  def create
    @pattern = Pattern.new(params[:pattern])
    respond_to do |format|
      if @pattern.save
        flash[:notice] = 'Pattern was successfully created.'
        format.html { redirect_to @pattern}
      else
        flash[:error] = 'Could not create pattern. ' + @pattern.errors.full_messages.join(", ")
        format.html {render action: "new"}
      end
    end
  end

  def index
    @patterns = Pattern.where(:type => nil)
    if @patterns.empty?
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
      @pattern_groups = {"Uncategorized" => []}
      @patterns.each do |pattern| 
        pattern.tag_list.each do |tag|
          @pattern_groups[tag] ||= []
          @pattern_groups[tag] << pattern
        end
        @pattern_groups["Uncategorized"] << pattern if pattern.tag_list.empty?
      end
      @ontology_groups = Ontology.pluck(:group).uniq.map do |group| 
        [group, Ontology.where(:does_exist => true, :group => group).collect{|ont| [ont.short_name, ont.id]}]
      end
    end
  end

  def update
    @pattern = Pattern.find(params[:id])
    if @pattern.update_attributes(params[:pattern])
      @pattern.touch
      flash[:notice] = "Pattern successfully saved!"
      render json: @pattern, :status => :ok
    else
      flash[:error] = "Could not save pattern!"
      render json: @pattern.errors, :status => :unprocessable_entity
    end
  end

  def destroy
    @pattern = Pattern.find(params[:id])
    qn = @pattern.name
    @pattern.destroy
    flash[:notice] = "Destroyed Pattern '#{qn}'"
    redirect_to patterns_path
  end
  
  def process_patterns
    if !params[:patterns]
      redirect_to patterns_path, :alert => "Please pick at least one target pattern!"
    else
      if params[:translate]
        if params[:patterns].size > 1
          redirect_to patterns_path, :alert => "You can only translate one pattern at a time!"
        else          
          redirect_to pattern_translate_path(Pattern.find(params[:patterns].first), Ontology.find(params[:ontology_id]))
        end
      elsif params[:combine]
        redirect_to combine_patterns_path({:patterns => params[:patterns]}) 
      else
        redirect_to patterns_path
      end
    end
  end
  
  def combine
    if params[:patterns].size != 2
      redirect_to patterns_path, :alert => "You can only combine exactly two patterns at a time!"
    else
      redirect_to patterns_path, :notice => "We're working on it..."
    end
  end

  def missing_concepts
    @pattern = Pattern.find(params[:pattern_id])
    @ontology = Ontology.find(params[:ontology_id])
    render :layout => false
  end

  def query
    @pattern = Pattern.find(params[:pattern_id])
    @repository = @pattern.ontology.repository || RdfRepository.new
    @queries = {
      "Cypher" => CypherQueryCreator.new(@pattern).query_string,
      "Sparql" => SparqlQueryCreator.new(@pattern).query_string
    }
  end

  def save_correspondence
    sources = (params[:source_element_ids] || []).reject{|x| x.blank?}.first
    targets = (params[:target_element_ids] || []).reject{|x| x.blank?}.first

    matched_concepts = if sources.blank? || targets.blank?
      flash[:error] = "You forgot to specify in or output elements. Please, watch the notifications in the top right corner!"
      []
    else
      input_elements = PatternElement.find(sources.split(","))
      output_elements = PatternElement.find(targets.split(","))
      @oc = ""#OntologyCorrespondence.for_elements!(input_elements, output_elements)
      if @oc.nil?
        flash[:error] = "Could not save correspondence! Contact your administrator"
        []
      else
        flash[:notice] = "Thanks for the correspondence!"
        params[:source_element_ids].collect{|id| id.to_s}
      end
    end
    render :json => matched_concepts
  end

  private

  def load_attributes_and_constraints!(pattern, static = false)
    # load existing relation constraints
    relations = pattern.relation_constraints.collect do |rc|
      {
        :source => rc.source.id, 
        :target => rc.target.id, 
        :url => static ? pattern_relation_constraint_static_path(pattern, rc) : pattern_relation_constraint_path(pattern, rc)
      }
    end

    # and attribute constraints, as well
    attributes = {}
    pattern.attribute_constraints.each do |ac|
      attributes[ac.node.id] ||= []
      attributes[ac.node.id] << if static
        pattern_attribute_constraint_static_path(pattern, ac)
      else
        pattern_attribute_constraint_path(pattern, ac)
      end
    end
    return attributes, relations
  end
end
