class Correspondence < ActiveRecord::Base
  include RdfSerialization
  class UnsupportedCorrespondence < Exception;end

  attr_accessor :node, :entity1, :entity2, :pattern_elements
  attr_accessible :measure, :relation
  belongs_to :onto1, :class_name => "Ontology"
  belongs_to :onto2, :class_name => "Ontology"
  has_many :pattern_element_matches, dependent: :destroy

  before_save :set_mapping_keys
  after_save :add_to_alignment
  after_destroy :remove_from_alignment

  scope :between, ->(o1,o2) { where(onto1_id: o1.id, onto2_id: o2.id)}
  SEPARATOR = "||"

  def self.construct(measure, relation, entity1, entity2, onto1, onto2)
    c = self.new(measure: measure, relation: relation)
    c.onto1 = onto1
    c.onto2 = onto2
    c.entity1 = entity1
    c.entity2 = entity2
    c.save
    return c
  end

  def rdf_types
    [Vocabularies::Alignment.Cell]
  end

  def url
    return ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:correspondences_path] + id.to_s
  end

  def ontology_matcher()
    OntologyMatcher.new(onto1, onto2)
  end

  def add_to_alignment()
    ontology_matcher.add_correspondence!(self)
  end

  def remove_from_alignment()
    ontology_matcher.remove_correspondence!(self)
  end

  def set_mapping_keys
    self.source_key = self.class.key_for_entity(entity1)
    self.target_key = self.class.key_for_entity(entity2)
  end

  # uses a set of elements provided by a user and creates a complex or simple correspondence
  # this method also checks whether this ontology previously existed through the mapping keys
  def self.from_elements(input_elements, output_elements)
    corr = where(source_key: key_for_entity(input_elements), target_key: key_for_entity(output_elements)).first
    corr ||= construct_from_elements(input_elements, output_elements)

    input_elements.each do |ie|
      output_elements.each do |oe|
        corr.pattern_element_matches.where(:matched_element_id => ie.id, :matching_element_id => oe.id).first_or_create
      end
    end
    return corr
  end

  def self.construct_from_elements(input_elements, output_elements)
    i_ont = input_elements.first.ontology
    o_ont = output_elements.first.ontology

    if input_elements.size == 1 && output_elements.size == 1
      i_el = input_elements.first
      o_el = output_elements.first
      return SimpleCorrespondence.construct(1.0, "=", i_el.rdf_type, o_el.rdf_type, i_ont, o_ont)
    else
      if !input_elements.all?{|el| el.ontology == i_ont} && !output_elements.collect{|el| el.ontology == o_ont}
        raise UnsupportedCorrespondence.new("All elements need to stem from the same ontology!")
      end
      return ComplexCorrespondence.construct(1.0, "=", input_elements, output_elements, i_ont, o_ont)
    end
  end

  def self.key_for_entity(thingy)
    thingy.is_a?(Array) ? thingy.collect{|ie| ie.rdf_type}.sort.join(SEPARATOR) : thingy
  end

  def self.candidates_for(o1, o2, elements, inverted = false)
    matches = {}
    combo_keys = {}
    # get all combinations of input elements and their according correspondence keys
    combinations = (1..elements.size).flat_map{|size| elements.combination(size).to_a}
    combinations.each{|combo| combo_keys[combo] = combo.collect{|el| el.rdf_type}.sort.join(SEPARATOR)}
    # determine which direction should we query
    target_key = inverted ? :target_key : :source_key
    Correspondence.between(o1,o2).where(target_key => combo_keys.values).each do |correspondence|
      # if we map two nodes of identical types, they have to get different correspondence instances
      comp_val = inverted ? correspondence.target_key : correspondence.source_key
      combo_keys.map{ |k,v| v==comp_val ? k : nil }.compact.each do |elements|
        matches[elements] ||= []
        matches[elements] << Correspondence.find(correspondence.id)
      end
    end
    return matches
  end
end