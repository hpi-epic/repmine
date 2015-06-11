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

  def self.for_pattern_and_ontologies(pattern, ontologies)
    tp = TranslationPattern.includes(:ontologies).where(:ontologies => {:id => ontologies.collect{|o| o.id}}, :pattern_id => pattern.id).first
    tp ||= TranslationPattern.new(:name => pattern_name(pattern, ontologies), :description => description(pattern, ontologies), :pattern_id => pattern.id)
    tp.ontologies += ontologies
    tp.save
    return tp
  end
  
  # legacy support
  def self.for_pattern_and_ontology(pattern, ontology)
    return self.for_pattern_and_ontologies(pattern, [ontology])
  end

  def self.pattern_name(pattern, ontologies)
    return "translation of '#{pattern.name}' to '#{ontologies.collect{|ont| ont.short_name}.join(", ")}'"
  end

  def self.description(pattern, ontologies)
    return "translates the pattern '#{pattern.name}' to the repository describe by ontology '#{ontologies.collect{|ont| ont.short_name}.join(", ")}'"
  end

  def self.model_name
    return Pattern.model_name
  end
  
  def input_elements
    return source_pattern.unmatched_elements(ontologies)
  end
  
  def ontology_matchers(source_ont)
    ontologies.collect{|target_ont| OntologyMatcher.new(source_ont, target_ont)}
  end
  
  # return correspondences for a given pattern
  def prepare!()
    already_mapped = Set.new
    
    # first try the unmatched input elements one by one
    input_elements.each do |pe|
      element_correspondences = ontologies.collect{|ont| pe.correspondences_to(ont)}.flatten
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
      next unless elements.collect{|pe| pe.ontology_id}.uniq.size != 1
      source_ont = elements.first.ontology
      element_correspondences = ontology_matchers(source_ont).collect{|om| om.correspondences_for_pattern_elements(elements)}.flatten
      
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
