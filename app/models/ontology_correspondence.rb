class OntologyCorrespondence < ActiveRecord::Base
  include RdfSerialization
  
  has_and_belongs_to_many :input_elements, :class_name => "PatternElement", :association_foreign_key => "input_element_id"
  has_and_belongs_to_many :output_elements, :class_name => "PatternElement", :association_foreign_key => "output_element_id"
  
  belongs_to :input_ontology, :class_name => "Ontology"
  belongs_to :output_ontology, :class_name => "Ontology"
  
  attr_accessible :measure, :relation, :input_ontology, :output_ontology
  attr_accessor :alignment, :ontology_matcher
  
  # creates a new correspondence and adds it to the alignment graph
  def self.for_elements!(input_elements, output_elements)
    input_ontology = input_elements.first.pattern.ontology
    output_ontology = output_elements.first.pattern.ontology
    oc = OntologyCorrespondence.create(:input_ontology => input_ontology, :output_ontology => output_ontology, :relation => "=", :measure => 1.0)
    oc.input_elements = input_elements
    oc.output_elements = output_elements
    oc.add_to_alignment_graph!
    return oc
  end
  
  def rdf_types
    [Vocabularies::Alignment.Cell]
  end
  
  def add_to_alignment_graph!
    ontology_matcher.add_correspondence!(self)
  end
  
  def ontology_matcher
    @ontology_matcher ||= OntologyMatcher.new(input_ontology, output_ontology)
  end
  
  # he, who must not be named...
  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:alignments_path] + self.id.to_s
  end
  
  def entity1
    return input_elements.size == 1 ? input_elements.first : input_elements
  end
  
  def entity2
    return output_elements.size == 1 ? output_elements.first : output_elements
  end  
  
  def rdf_statements
    [
      [alignment, Vocabularies::Alignment.map, resource],
      [resource, Vocabularies::Alignment.entity1, RDF::Resource.new(input_elements.first.rdf_type)],
      [resource, Vocabularies::Alignment.entity2, RDF::Resource.new(output_elements.first.rdf_type)],
      [resource, Vocabularies::Alignment.measure, measure],
      [resource, Vocabularies::Alignment.relation, relation]
    ]
  end
end