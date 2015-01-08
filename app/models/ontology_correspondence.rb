class OntologyCorrespondence < Struct.new(:measure, :relation, :entity1, :entity2)
  include RdfSerialization

  #has_and_belongs_to_many :input_elements, :class_name => "PatternElement", :association_foreign_key => "input_element_id"
  #has_and_belongs_to_many :output_elements, :class_name => "PatternElement", :association_foreign_key => "output_element_id"

  #attr_accessible :measure, :relation, :entity1, :entity2

  # creates a new correspondence and adds it to the alignment graph
  #def self.for_elements!(input_elements, output_elements)
  #  oc = OntologyCorrespondence.create(:relation => "=", :measure => 1.0)
  #  oc.input_elements = input_elements
  #  oc.output_elements = output_elements
  #  return oc
  #end

  def rdf_types
    [Vocabularies::Alignment.Cell]
  end

  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:alignments_path] + self.id.to_s
  end

  #def entity1
  #  return input_elements.first.rdf_type
  #end

  #def entity2
  #  return output_elements.first.rdf_type
  #end
  
  def equal_to?(other)
    return entity1 == other.entity1 && entity2 == other.entity2 && relation == other.relation
  end
  
  def xml_node(doc)
    map = Nokogiri::XML::Node.new "map", doc
    cell = Nokogiri::XML::Node.new("Cell", doc)
    map << cell
    e1 = Nokogiri::XML::Node.new("entity1", doc)
    e1["rdf:resource"] = self.entity1
    e2 = Nokogiri::XML::Node.new("entity2", doc)
    e2["rdf:resource"] = self.entity2
    m = Nokogiri::XML::Node.new("measure", doc)
    m["rdf:datatype"] = RDF::XSD.float.to_s
    m.content = self.measure
    r = Nokogiri::XML::Node.new("relation", doc)
    r.content = self.relation
    cell << e1 << e2 << m << r
    return map
  end
end
