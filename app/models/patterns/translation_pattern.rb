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

  def self.for_pattern_and_ontologies(pattern, ontologies)
    tp = TranslationPattern.includes(:ontologies).where(:ontologies => {:id => ontologies.collect{|o| o.id}}, :pattern_id => pattern.id).first
    tp ||= TranslationPattern.new(:name => pattern_name(pattern, ontologies), :description => description(pattern, ontologies), :pattern_id => pattern.id)
    tp.ontologies += ontologies
    tp.save
    return tp
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
  
  def match!()
    ontologies.collect do |target_ont|
      source_pattern.ontologies.each do |source_ont|
        OntologyMatcher.new(source_ont, target_ont).match!
      end
    end
  end
  
  # return correspondences for a given pattern
  def prepare!()
    match!
    mappings = get_simple_mappings
    mappings.merge!(get_complex_mappings)
    check_for_ambiguous_mappings(mappings)
    add_pattern_elements!(mappings)
    connect_pattern_elements!(mappings)
    create_matches(mappings)
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
      pe.save!
    end
  end
  
  def create_matches(mappings)
    mappings.each_pair do |input_elements, target_elements|
      input_elements.each do |pe_id|
        target_elements.each do |te|
          PatternElementMatch.create(:matched_element => PatternElement.find(pe_id), :matching_element => te)
        end
      end
    end
  end
  
  def add_pattern_elements!(mappings)
    mappings.values.each do |target_elements|
      target_elements.each do |te|
        self.pattern_elements << te
        te.save!(validate: false)
      end
    end
  end
  
  def check_for_ambiguous_mappings(mappings)
    mappings.keys.sort_by{|key| key.size}.each_with_index do |key, index|
      # option 1: more than one possible output subgraphs
      raise AmbiguousTranslation.new("too many mappings for element #{key}") if mappings[key].size > 1
      # option 2: the current key is included in at least one other mapping
      raise AmbiguousTranslation.new("ambiguous mappings for element #{key}") if mappings.keys[index+1..-1].any?{|other_key| (key - other_key).empty?}
    end
    mappings.each_pair do |key, targets|
      mappings[key] = targets.flatten
    end
  end
  
  def get_simple_mappings
    mappings = {}
    # first try the unmatched input elements one by one
    input_elements.each do |pe|
      ontologies.collect{|ont| pe.correspondences_to(ont)}.flatten.each do |correspondence|
        mappings[[pe.id]] ||= []
        mappings[[pe.id]] << correspondence.pattern_elements
      end
    end
    return mappings
  end  
  
  def get_complex_mappings()
    mappings = {}
    
    # let's construct all possbile combinations of the input pattern's unmatched elements
    (2..input_elements.size).flat_map{|size| input_elements.combination(size).to_a}.reverse.each do |elements|
      # only try to match combinations of the same ontology
      next if elements.collect{|pe| pe.ontology_id}.uniq.size != 1
      
      mapping_key = elements.collect{|pe| pe.id}
      ontology_matchers(elements.first.ontology).each do |om|
        om.correspondences_for_pattern_elements(elements).each do |correspondence|
          mappings[mapping_key] ||= []
          mappings[mapping_key] << correspondence.pattern_elements
        end
      end
    end
    return mappings
  end
end
