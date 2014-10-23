class TranslationPattern < Pattern
  
  attr_accessible :pattern_id, :target_ontology_id
  
  belongs_to :pattern
  belongs_to :target_ontology, :class_name => "Ontology"
  
  def self.for_pattern_and_repository(pattern, ontology)
    params = {:name => pattern_name(pattern, ontology), :description => description, :ontology_ids => [ontology.id]}
    return self.where(:pattern_id => pattern.id, :target_ontology_id => ontology.id).first_or_create(params)
  end
  
  def self.pattern_name(pattern, ontology)
    return "translation of '#{pattern.name}' to '#{ontology.short_name}'"
  end
  
  def self.description
    return "translates the pattern to the repository"
  end

  def self.model_name
    return Pattern.model_name
  end

  def infer_correspondences(selected_elements)
    input_graph = get_subgraph(selected_elements)
    output_graph = get_subgraph(recent_changes)
    # outline of the algorithm:
    # - get all changes since last save
    # - throw them into the rule engine along with the input graph
    # - save the correspondence
    # - report back
  end
  
end