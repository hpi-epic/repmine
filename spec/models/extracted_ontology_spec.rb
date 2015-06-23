require 'rails_helper'

RSpec.describe ExtractedOntology, :type => :model do
  it "should create a fancy graph for the schema" do
    s = FactoryGirl.create(:repository).ontology
    owc = OwlClass.new(s, "MyClass", "http://example.org/MyClass")
    owc.add_attribute("my_attribute", "a type")
    owc.add_relation("my_relation", owc)
    s.rdf_graph
  end

  it "should create valid rdf/xml..." do
    ont = FactoryGirl.create(:extracted_ontology)
    owc = OwlClass.new(ont, "MyClass", "http://example.org/MyClass")
    owc.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_navigation_path, RDF::Literal.new("hello world"))
    owc.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new("hello world"))
    RDF::RDFXML::Reader.new(ont.rdf_xml)
  end
  
  it "should not be possible to add an owl class multiple times" do
    ont = ExtractedOntology.new()
    owl_class = OwlClass.new(ont, "owl_class", "http://example.org/owl_class")
    assert_include ont.classes, owl_class
    ont.add_class(owl_class)
    assert_equal 1, ont.classes.size
  end
end
