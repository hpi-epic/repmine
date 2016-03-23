class TranslationPattern < Pattern

  class AmbiguousTranslation < Error; end

  attr_accessible :pattern_id
  belongs_to :source_pattern, :foreign_key => "pattern_id", :class_name => "Pattern"

  def self.for_pattern_and_ontologies(pattern, ontologies)
    tp = existing_translation_pattern(pattern, ontologies)
    tp ||= TranslationPattern.new(:name => pattern_name(pattern, ontologies), :description => description(pattern, ontologies), :pattern_id => pattern.id)
    tp.ontologies += ontologies
    tp.save
    return tp
  end

  def self.existing_translation_pattern(pattern, ontologies)
    TranslationPattern.includes(:ontologies).where(:ontologies => {:id => ontologies.collect{|o| o.id}}, :pattern_id => pattern.id).first
  end

  def self.pattern_name(pattern, ontologies)
    "'#{pattern.name}' on '#{ontologies.collect{|ont| ont.short_name}.join(", ")}'"
  end

  def self.description(pattern, ontologies)
    "Translates pattern '#{pattern.name}' to ontologies: '#{ontologies.collect{|ont| ont.short_name}.join(", ")}'."
  end

  def self.model_name
    Pattern.model_name
  end

  def unmatched_source_elements
    source_pattern.unmatched_elements(ontologies)
  end

  def ambiguous_correspondences
    check_for_ambiguous_mappings(all_mappings)
  end

  def matched_source_elements
    source_pattern.matched_elements(ontologies)
  end

  def ontology_matchers(source_ont)
    ontologies.collect{|target_ont| OntologyMatcher.new(source_ont, target_ont)}
  end

  def matching_groups
    PatternElementMatch.matching_groups(pattern_elements.map(& :id))
  end

  def match!()
    ontologies.collect do |target_ont|
      source_pattern.ontologies.each do |source_ont|
        OntologyMatcher.new(source_ont, target_ont).match!
      end
    end
  end

  # return correspondences for a given pattern
  def prepare!(selected_correspondences = [])
    match!
    mappings = all_mappings()
    resolve_ambiguities(mappings, selected_correspondences)
    ambiguities = check_for_ambiguous_mappings(mappings)
    raise AmbiguousTranslation.new unless ambiguities.empty?
    flatten_mappings(mappings)
    add_pattern_elements!(mappings)
    connect_pattern_elements!(mappings)
  end

  def all_mappings()
    mappings = {}
    unmatched_source_elements.group_by{|el| el.ontology}.each_pair do |ontology, elements|
      ontology_matchers(ontology).each do |om|
        om.correspondences_for(elements).each_pair do |matched_elements, correspondences|
          mappings[matched_elements] ||= []
          mappings[matched_elements].concat(correspondences)
        end
      end
    end
    return mappings
  end

  def flatten_mappings(mappings)
    mappings.each_pair do |key, targets|
      mappings[key] = targets.first
      mappings[key].pattern_elements = unmatched_subgraph(mappings[key].pattern_elements)
    end
  end

  def connect_pattern_elements!(mappings)
    connector = ConnectionFinder.new()
    connector.load_to_engine!(mappings, source_pattern)

    pattern_elements.each do |pe|
      if pe.is_a?(AttributeConstraint)
        pe.node ||= connector.node_for_ac(pe)
      elsif pe.is_a?(RelationConstraint)
        pe.source ||= connector.source_for_rc(pe)
        pe.target ||= connector.target_for_rc(pe)
      end
      pe.valid? ? pe.save! : pe.destroy
    end
  end

  def add_pattern_elements!(mappings)
    # for each mapping pair
    mappings.each_pair do |input_elements, correspondence|
      # and the elements defined by the correspondence
      correspondence.pattern_elements.each do |te|
        # we first store the element in the translation pattern
        self.pattern_elements << te
        # save it (without validation)
        te.save!(validate: false)
        input_elements.each do |ie_id|
          correspondence.pattern_element_matches.where(:matched_element_id => ie_id, :matching_element_id => te.id).first_or_create!
        end
      end
    end
  end

  def check_for_ambiguous_mappings(mappings)
    ambiguities = {}
    sorted_keys = mappings.keys.sort_by{|key| key.size}
    sorted_keys.each_with_index do |key, index|
      # option 1: more than one possible output subgraphs
      ambiguities[key] = mappings[key] if mappings[key].size > 1
      # option 2: the current key or parts of it is included in at least one other mapping
      sorted_keys[index+1..-1].select{|other_key| (key - other_key).size != key.size}.each do |alt_key|
        ambiguities[alt_key] = mappings[alt_key]
        ambiguities[key] = mappings[key]
      end
    end
    return ambiguities
  end

  def resolve_ambiguities(mappings, selected_correspondences)
    if selected_correspondences.empty?
      return mappings
    else
      selected_correspondences.each_pair do |element_ids, correspondence_id|
        real_target = mappings.find{|k,v| !v.find{|corr| corr.id == correspondence_id}.nil?}
        real_target = real_target.nil? ? element_ids : real_target.first.collect{|el| el.id}
        mappings.each do |elements, correspondences|
          if !(elements.collect{|el| el.id} & real_target).empty?
            mappings[elements] = mappings[elements].select{|corr| corr.id == correspondence_id}
            mappings.delete(elements) if mappings[elements].empty?
          end
        end
      end
    end
  end

  # we check whether we find unmatched doppelgaengers of all the elements
  def unmatched_subgraph(elements)
    candidates = unmatched_elements(source_pattern.ontologies)
    doppelgaengers = elements.collect{|el| candidates.find{|cand| cand.equal_to?(el)}}.compact
    if doppelgaengers.uniq.size == elements.size
      return doppelgaengers
    else
      return elements
    end
  end
end