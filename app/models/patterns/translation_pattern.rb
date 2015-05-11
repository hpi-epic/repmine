# == Schema Information
#
# Table name: patterns
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  ontology_id :integer
#  type        :string(255)
#  pattern_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class TranslationPattern < Pattern
  
  class AmbiguousTranslation < Error; end

  attr_accessible :pattern_id
  belongs_to :source_pattern, :foreign_key => "pattern_id", :class_name => "Pattern"

  after_create :prepare!

  def self.for_pattern_and_ontology(pattern, ontology)
    params = {:name => pattern_name(pattern, ontology), :description => description}
    translation_pattern = self.where(:pattern_id => pattern.id, :ontology_id => ontology.id).first_or_create(params)
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
  
  def ontology_matcher
    return self.source_pattern.ontology_matcher(self.ontology)
  end

  # this loads nodes and relations for concepts we already know are equivalent
  def prepare!
    correspondences_for_pattern(source_pattern).each do |correspondence|
      self.pattern_elements.concat(correspondence.pattern_elements)
      pattern_elements.each{|pe| pe.save!}
    end
  end
  
  def input_elements
    return source_pattern.pattern_elements
  end
  
  # return correspondences for a given pattern
  def correspondences_for_pattern(pattern)
    correspondences = []
    already_mapped = Set.new
    
    # first try the elements one by one
    source_pattern.pattern_elements.each do |pe|
      element_correspondences = ontology_matcher.correspondences_for_concept(pe.rdf_type)
      raise AmbiguousTranslation if element_correspondences.size > 1
      already_mapped << pe unless element_correspondences.empty?
      correspondences.concat(element_correspondences)
    end
    
    # let's construct all possbile combinations of the input pattern's elements
    (2..input_elements.size).flat_map{|size| input_elements.combination(size).to_a}.reverse.each do |elements|
      element_correspondences = ontology_matcher.correspondences_for_pattern_elements(elements)
      unless element_correspondences.empty?
        raise AmbiguousTranslation if element_correspondences.size > 1
        raise AmbiguousTranslation if elements.any?{|el| already_mapped.include?(el)}
        correspondences.concat(element_correspondences)
        already_mapped.merge(elements)
      end
    end

    return correspondences
  end
end
