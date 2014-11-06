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
    offset = pattern.node_offset + 120
    pattern.pattern_elements.each do |input_element|
      corr = correspondences.find{|c| c.input_elements.include?(input_element)}
      unless corr.nil?
        corr.output_elements.each do |output_element|
          output_element.pattern = self
          output_element.equivalent = input_element
          if input_element.is_a?(Node)
            output_element.x = input_element.x + offset
            output_element.y = input_element.y
          end
          output_element.save
        end
      end
    end
  end
end