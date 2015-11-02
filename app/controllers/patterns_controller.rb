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

  def bootstrap_translation(source_pattern, target_ontology)
    # no need to translate a pattern to one of its own ontologies
    if source_pattern.ontologies.include?(target_ontology)
      redirect_to patterns_path, :notice => "No self-translation necessary!" and return
    end
    target_pattern = TranslationPattern.for_pattern_and_ontologies(source_pattern, [target_ontology])
    target_pattern.prepare!
    redirect_to pattern_translate_path(source_pattern, target_pattern)
  end

  def translate
    @source_pattern = Pattern.find(params[:pattern_id])
    @target_pattern = TranslationPattern.find(params[:target_id])
    @source_pattern.auto_layout!

    @controls_offset = @source_pattern.node_offset - 30
    @node_offset = 0
    if @target_pattern.pattern_elements.all?{|pe| pe.x == 0 && pe.y == 0}
      @target_pattern.store_auto_layout!
      @node_offset = @controls_offset
    end

    @source_attributes, @source_relations = load_attributes_and_constraints!(@source_pattern, true)
    @target_attributes, @target_relations = load_attributes_and_constraints!(@target_pattern)
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
        format.html {render :new}
      end
    end
  end

  def index
    if Pattern.count == 0
      flash[:notice] = "No Patterns available. Please create a new one!"
      redirect_to new_pattern_path
    else
      @pattern_groups = Pattern.grouped
      @ontology_groups = Ontology.grouped
      @repositories = Repository.all
    end
    @title = "Pattern Overview"
  end

  def update
    @pattern = Pattern.find(params[:id])
    if @pattern.update_attributes(params[:pattern])
      @pattern.touch
      flash[:notice] = "Pattern successfully saved!"
      if @pattern.is_a?(TranslationPattern)
        redirect_to pattern_unmatched_node_path(@pattern)
      else
        render json: {}, :status => :ok
      end
    else
      flash[:error] = "Could not save pattern!"
      render json: @pattern.errors, :status => :unprocessable_entity
    end
  end

  def unmatched_node
    translation_pattern = Pattern.find(params[:pattern_id])
    @matches = translation_pattern.find_element_matches(translation_pattern.source_pattern.ontologies)
    @next_unmatched_element = translation_pattern.unmatched_source_elements.first
    respond_to :js
  end

  def destroy
    @pattern = Pattern.find(params[:id])
    qn = @pattern.name
    @pattern.destroy
    flash[:notice] = "Destroyed Pattern '#{qn}'"
    redirect_to patterns_path
  end

  def transmogrify
    if !params[:patterns]
      redirect_to patterns_path, :alert => "Please pick at least one target pattern!"
    else
      if params[:translate]
        if params[:patterns].size > 1
          redirect_to patterns_path, :alert => "You can only translate one pattern at a time!"
        else
          bootstrap_translation(Pattern.find(params[:patterns].first), Ontology.find(params[:ontology_ids]))
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
    unless params[:ontology_id].nil?
      @ontology = Ontology.find(params[:ontology_id])
      @t_pattern = TranslationPattern.existing_translation_pattern(@pattern, [@ontology])
      flash[:error] = "No translation available, yet, for #{@pattern.name} to #{@ontology.short_name}" if @t_pattern.nil?
    end
    @queries = {
      "Cypher" => CypherQueryCreator.new(@t_pattern || @pattern).query_string,
      "Sparql" => SparqlQueryCreator.new(@t_pattern || @pattern).query_string
    }
    @ontology_groups = Ontology.grouped
    @title = "Queries for '#{@pattern.name}'"
  end

  def save_correspondence
    sources = (params[:source_element_ids] || []).reject{|x| x.blank?}.first
    targets = (params[:target_element_ids] || []).reject{|x| x.blank?}.first
    matched_concepts = []

    if sources.blank? || targets.blank?
      flash[:error] = "Missing input/output elements!"
    else
      input_elements = PatternElement.find(sources.split(","))
      output_elements = PatternElement.find(targets.split(","))
      begin
        @oc = Correspondence.from_elements(input_elements, output_elements)
        flash[:notice] = "Correspondence saved!"
      rescue Correspondence::UnsupportedCorrespondence => e
        flash[:error] = "Could not save correspondence! #{e.message}"
      end
    end
    redirect_to :unmatched_node
  end

  private

  def load_attributes_and_constraints!(pattern, static = false)
    # load existing relation constraints
    relations = pattern.relation_constraints.collect do |rc|
      {
        :source => rc.source.id,
        :target => rc.target.id,
        :url => static ? relation_constraint_static_path(rc) : relation_constraint_path(rc)
      }
    end

    # and attribute constraints, as well
    attributes = {}
    pattern.attribute_constraints.each do |ac|
      attributes[ac.node.id] ||= []
      attributes[ac.node.id] << if static
        attribute_constraint_static_path(ac)
      else
        attribute_constraint_path(ac)
      end
    end
    return attributes, relations
  end
end