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
    begin
      oc.add_to_alignment_graph!
    rescue Exception => e
      oc.destroy
      return nil
    end
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

  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:alignments_path] + self.id.to_s
  end

  def entity1
    return input_elements.first.rdf_type
  end

  def entity2
    return output_elements.first.rdf_type
  end
  
  def equal_to?(other)
    return entity1 == other.entity1 && entity2 == other.entity2
  end
  
  def xml_node(doc, invert = false)
    map = Nokogiri::XML::Node.new "map", doc
    cell = Nokogiri::XML::Node.new("Cell", doc)
    map << cell
    e1 = Nokogiri::XML::Node.new("entity1", doc)
    e1["rdf:resource"] = invert ? self.entity2 : self.entity1
    e2 = Nokogiri::XML::Node.new("entity2", doc)
    e2["rdf:resource"] = invert ? self.entity1 : self.entity2
    m = Nokogiri::XML::Node.new("measure", doc)
    m["rdf:datatype"] = RDF::XSD.float.to_s
    m.content = self.measure
    r = Nokogiri::XML::Node.new("relation", doc)
    r.content = self.relation
    cell << e1 << e2 << m << r
    return map
  end
end
