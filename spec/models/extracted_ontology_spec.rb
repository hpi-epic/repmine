require 'spec_helper'

describe ExtractedOntology do
  it "should create a fancy graph for the schema" do
    s = create(:repository).ontology
    owc = OwlClass.new(s, "MyClass")
    owc.add_attribute("my_attribute", "a type")
    owc.add_relation("my_relation", owc)
    lambda {s.rdf_graph}.should_not raise_error
  end
end