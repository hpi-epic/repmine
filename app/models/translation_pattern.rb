class TranslationPattern < Pattern
  
  attr_accessible :pattern_id, :repository_id
  belongs_to :repository
  belongs_to :pattern
  
  def self.for_pattern_and_repository(pattern, repository)
    params = {:ontology_ids => [repository.ontology.id], :name => pattern_name(pattern, repository), :description => description}
    return self.where(:pattern_id => pattern.id, :repository_id => repository.id).first_or_create(params)
  end
  
  def self.pattern_name(pattern, repository)
    return "translation of '#{pattern.name}' to '#{repository.name}'"
  end
  
  def self.description
    return "translates the pattern to the repository"
  end

  def self.model_name
    return Pattern.model_name
  end
  
  def create_repository_name!
    self.repository_name = ontologies.first.repository_name
  end
end
