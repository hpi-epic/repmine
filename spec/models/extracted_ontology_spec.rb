require 'spec_helper'

describe ExtractedOntology do
  it "should create a fancy graph for the schema" do
    s = create(:repository).ontology
    owc = OwlClass.new(s, "MyClass")
    owc.add_attribute("my_attribute", "a type")
    owc.add_relation("my_relation", owc)
    lambda {s.rdf_graph}.should_not raise_error
  end
  
  it "should create valid rdf/xml..." do 
    ont = MongoDbRepository.create({:db_name => "sample_db", :name => "sample_db"}).ontology
    owc = OwlClass.new(ont, "MyClass")
    owc.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_navigation_path, RDF::Literal.new("hello world"))
    owc.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new("hello world"))
    ont.create_graph!
    lambda {RDF::RDFXML::Reader.new(ont.rdf_xml)}.should_not raise_error
  end
end