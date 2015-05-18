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
    params = {:name => pattern_name(pattern, ontology), :description => description(pattern, ontology)}
    translation_pattern = self.where(:pattern_id => pattern.id, :ontology_id => ontology.id).first_or_create(params)
    return translation_pattern
  end

  def self.pattern_name(pattern, ontology)
    return "translation of '#{pattern.name}' to '#{ontology.short_name}'"
  end

  def self.description(pattern, ontology)
    return "translates the pattern '#{pattern.name}' to the repository describe by ontology '#{ontology.short_name}'"
  end

  def self.model_name
    return Pattern.model_name
  end
  
  def ontology_matcher
    return source_pattern.ontology_matcher(ontology)
  end
  
  def input_elements
    return source_pattern.unmatched_elements(ontology)
  end
  
  # return correspondences for a given pattern
  def prepare!()
    already_mapped = Set.new
    
    # first try the unmatched input elements one by one
    input_elements.each do |pe|
      element_correspondences = ontology_matcher.correspondences_for_concept(pe.rdf_type)
      raise AmbiguousTranslation if element_correspondences.size > 1
      unless element_correspondences.empty?
        already_mapped << pe
        element_correspondences.first.pattern_elements.each do |te|
          pattern_elements << te
          PatternElementMatch.create!(:matched_element => pe, :matching_element => te)
        end        
      end
    end
    
    # let's construct all possbile combinations of the input pattern's unmatched elements
    (2..input_elements.size).flat_map{|size| input_elements.combination(size).to_a}.reverse.each do |elements|
      element_correspondences = ontology_matcher.correspondences_for_pattern_elements(elements)
      unless element_correspondences.empty?
        raise AmbiguousTranslation if element_correspondences.size > 1
        raise AmbiguousTranslation if elements.any?{|el| already_mapped.include?(el)}
        already_mapped.merge(elements)
        element_correspondences.first.pattern_elements.each do |te|
          pattern_elements << te
          elements.each{|pe| PatternElementMatch.create!(:matched_element => pe, :matching_element => te)}
        end
      end
    end
    
    pattern_elements.each{|pe| pe.save}
  end
end
