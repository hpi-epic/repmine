class PatternsController < ApplicationController

  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'

  def new
    @pattern = Pattern.new
    @title = "Create new pattern"
  end

  def show
    @pattern = Pattern.find(params[:id])
    # little performance tweak, only load the hierarchy, if we have nodes that go with it
    @attributes, @relations = load_attributes_and_constraints!(@pattern)
    @title = "'#{@pattern.name}' Pattern"
  end
  
  def translate
    @source_pattern = Pattern.find(params[:pattern_id])
    @source_pattern.auto_layout!
    @source_attributes, @source_relations = load_attributes_and_constraints!(@source_pattern, true)
    

    @target_ontologies = Ontology.find(params[:ontology_id])
    @target_pattern = TranslationPattern.for_pattern_and_ontologies(@source_pattern, [@target_ontologies])
    @target_pattern.prepare!

    @controls_offset = @source_pattern.node_offset - 30
    @node_offset = 0
    if @target_pattern.pattern_elements.all?{|pe| pe.x == 0 && pe.y == 0}
      @target_pattern.store_auto_layout!
      @node_offset = @controls_offset      
    end
    
    @target_attributes, @target_relations = load_attributes_and_constraints!(@target_pattern)
    @matched_elements = @source_pattern.matched_elements(@target_ontologies).collect{|me| me.id.to_s}
    @title = "Translating '#{@source_pattern.name}'"
  end

  def create
    ontologies = Ontology.find(params[:pattern].delete(:ontology_ids).reject{|oid| oid.blank?})
    @pattern = Pattern.new(params[:pattern])
    @pattern.ontologies = ontologies
    
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
    if Pattern.count == 0
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
      @pattern_groups = Pattern.grouped
      @ontology_groups = Ontology.pluck(:group).uniq.map do |group| 
        [group, Ontology.where(:does_exist => true, :group => group).collect{|ont| [ont.short_name, ont.id]}]
      end
      @repositories = Repository.all
    end
    @title = "Pattern Overview"
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
          redirect_to pattern_translate_path(Pattern.find(params[:patterns].first), Ontology.find(params[:ontology_ids]))
        end
      elsif params[:monitor]
        task_ids = MonitoringTask.create_multiple(params[:patterns], params[:repository_id])
        redirect_to check_monitoring_tasks_path(:task_ids => task_ids)
      else
        redirect_to patterns_path, :alert => "How did you get here, anyway?"
      end
    end
  end

  def query
    @pattern = Pattern.find(params[:pattern_id])
    @queries = {
      "Cypher" => CypherQueryCreator.new(@pattern).query_string,
      "Sparql" => SparqlQueryCreator.new(@pattern).query_string
    }
    @potential_repositories = {
      "Cypher" => Neo4jRepository.where(:ontology_id => @pattern.ontologies),
      "Sparql" => RdfRepository.where(:ontology_id => @pattern.ontologies)
    }
    @title = "Queries for '#{@pattern.name}'"    
  end
  
  def save_correspondence
    sources = (params[:source_element_ids] || []).reject{|x| x.blank?}.first
    targets = (params[:target_element_ids] || []).reject{|x| x.blank?}.first
    matched_concepts = []

    if sources.blank? || targets.blank?
      flash[:error] = "You forgot to specify in or output elements. Please, watch the notifications in the top right corner!"
    else
      input_elements = PatternElement.find(sources.split(","))
      output_elements = PatternElement.find(targets.split(","))
      begin
        @oc = ComplexCorrespondence.from_elements(input_elements, output_elements)
        @oc.add_to_alignment!
        input_elements.each{|ie|
          output_elements.each{|oe|
            PatternElementMatch.create(:matched_element => ie, :matching_element => oe)
          }
        }
        flash[:notice] = "Thanks for the correspondence!"
        matched_concepts = params[:source_element_ids].collect{|id| id.to_s}
      rescue SimpleCorrespondence::UnsupportedCorrespondence => e
        flash[:error] = "Could not save correspondence! #{e.message}"
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