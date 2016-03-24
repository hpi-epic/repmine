class PatternsController < ApplicationController

  autocomplete :tag, :name, :class_name => 'ActsAsTaggableOn::Tag'

  def new
    @ontologies = Ontology.all
    if @ontologies.empty?
      flash[:notice] = "No ontologies present. Create one or extract one from a repository."
      redirect_to new_ontology_path
    end
    @pattern = Pattern.new
    @title = "Create new pattern"
  end

  def show
    @pattern = Pattern.find(params[:id])
    @attributes, @relations = load_attributes_and_constraints!(@pattern)
    @title = "'#{@pattern.name}' Pattern"
  end

  def prepare_translation
    source_pattern = Pattern.find(params[:pattern_id])
    target_ontology = Ontology.find(params[:ontology_ids])
    # no need to translate a pattern to one of its own ontologies
    if source_pattern.ontologies.include?(target_ontology)
      redirect_to source_pattern, :notice => "No self-translation necessary!" and return
    end

    # otherwise, find (or create) the translation pattern and prepare it, again
    target_pattern = TranslationPattern.for_pattern_and_ontologies(source_pattern, [target_ontology])
    begin
      selected_correspondences = {}
      (params[:correspondence_id] || {}).each_pair{|k,v| selected_correspondences[[k.to_i]] = v.to_i}
      target_pattern.prepare!(selected_correspondences)
      redirect_to pattern_translate_path(target_pattern)
    rescue TranslationPattern::AmbiguousTranslation => e
      redirect_to pattern_correspondence_selection_path(target_pattern)
    end
  end

  def correspondence_selection
    @pattern = TranslationPattern.find(params[:pattern_id])
    @acs = @pattern.ambiguous_correspondences()
    # we collect all intersections of each key with other keys
    @groups = @acs.keys.collect{|key| @acs.keys.select{|kk| !(key & kk).empty?}}.uniq
    # but throw those away, whose elements are not entirely mutually exclusive
    @groups.reject!{|key| key.inject(:&).empty?}
  end

  def translate
    # find the pattern and auto layout the source pattern
    @target_pattern = TranslationPattern.find(params[:pattern_id])
    @source_pattern = @target_pattern.source_pattern
    @source_pattern.auto_layout!

    # get the control and node offsets so we don't have overlapping patterns
    @controls_offset = @source_pattern.node_offset - 30
    @node_offset = 0
    if @target_pattern.pattern_elements.all?{|pe| pe.x == 0 && pe.y == 0}
      @target_pattern.store_auto_layout!
      @node_offset = @controls_offset + 100
    end

    # finally, load the elements of both pattern
    @source_attributes, @source_relations = load_attributes_and_constraints!(@source_pattern, true)
    @target_attributes, @target_relations = load_attributes_and_constraints!(@target_pattern)
    @title = @target_pattern.name
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

  def update
    @pattern = Pattern.find(params[:id])
    if @pattern.update_attributes(params[:pattern])
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
    translation_pattern = TranslationPattern.find(params[:pattern_id])
    @matched_elements = translation_pattern.matched_source_elements
    @next_unmatched_element = translation_pattern.unmatched_source_elements.first
    respond_to :js
  end

  def query
    @pattern = Pattern.find(params[:pattern_id])
    @repositories = Repository.where(ontology_id: @pattern.ontologies.map(&:id))
    @queries = if @repositories.any?{|repo| repo.is_a?(Neo4jRepository)}
      {"Neo4j" => CypherQueryCreator.new(@pattern).query_string}
    else
      {"Sparql" => SparqlQueryCreator.new(@pattern).query_string}
    end
    @title = "Queries for '#{@pattern.name}'"
    render layout: false
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