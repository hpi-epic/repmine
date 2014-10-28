class TranslationPattern < Pattern
  
  attr_accessible :pattern_id, :target_ontology_id
  
  belongs_to :pattern
  belongs_to :target_ontology, :class_name => "Ontology"
  
  after_create :prepare!
  
  def self.for_pattern_and_ontology(pattern, ontology)
    params = {:name => pattern_name(pattern, ontology), :description => description, :ontology_ids => [ontology.id]}
    translation_pattern = self.where(:pattern_id => pattern.id, :target_ontology_id => ontology.id).first_or_create(params)
    return translation_pattern
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
  
  # this loads nodes and relations for concepts we already know are equivalent
  def prepare!
    correspondences = pattern.match_concepts(ontologies.first)
    pattern.nodes.each do |node|
      corr = correspondences.find{|c| c.entity1 == node.rdf_type}
      unless corr.nil?
        new_node = create_node!
        new_node.rdf_type = corr.entity2
        new_node.equivalent = node
        new_node.save
      end
    end
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