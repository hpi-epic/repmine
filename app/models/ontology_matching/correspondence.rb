class Correspondence < ActiveRecord::Base
  include RdfSerialization
  class UnsupportedCorrespondence < Exception;end

  attr_accessor :node, :entity1, :entity2
  attr_accessible :measure, :relation
  belongs_to :onto1, :class_name => "Ontology"
  belongs_to :onto2, :class_name => "Ontology"
  has_many :pattern_element_matches, dependent: :destroy

  after_save :add_to_alignment
  after_destroy :remove_from_alignment

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

  # uses a set of elements provided by a user and creates a complex or simple correspondence
  def self.from_elements(input_elements, output_elements)
    corr = if input_elements.size == 1 && output_elements.size == 1
      i_el = input_elements.first
      o_el = output_elements.first
      SimpleCorrespondence.construct(1.0, "=", i_el.rdf_type, o_el.rdf_type, i_el.ontology, o_el.ontology)
    else
      i_ont = input_elements.first.ontology
      o_ont = output_elements.first.ontology
      if !input_elements.all?{|el| el.ontology == i_ont} && !output_elements.collect{|el| el.ontology == o_ont}
        raise UnsupportedCorrespondence.new("All elements need to stem from the same ontology!")
      end
      ComplexCorrespondence.construct(1.0, "=", input_elements, output_elements, i_ont, o_ont)
    end

    input_elements.each do |ie|
      output_elements.each do |oe|
        corr.pattern_element_matches.create(:matched_element => ie, :matching_element => oe)
      end
    end

    return corr
  end
end