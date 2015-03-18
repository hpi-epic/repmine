# == Schema Information
#
# Table name: ontologies
#
#  id          :integer          not null, primary key
#  url         :string(255)
#  description :text
#  short_name  :string(255)
#  group       :string(255)
#  does_exist  :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe ExtractedOntology, :type => :model do
  it "should create a fancy graph for the schema" do
    s = FactoryGirl.create(:repository).ontology
    owc = OwlClass.new(s, "MyClass")
    owc.add_attribute("my_attribute", "a type")
    owc.add_relation("my_relation", owc)
    expect{s.rdf_graph}.to_not raise_error
  end

  it "should create valid rdf/xml..." do
    ont = FactoryGirl.create(:extracted_ontology)
    owc = OwlClass.new(ont, "MyClass")
    owc.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_navigation_path, RDF::Literal.new("hello world"))
    owc.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new("hello world"))
    expect{RDF::RDFXML::Reader.new(ont.rdf_xml)}.to_not raise_error
  end

  it "should raise an error if the graph is not set" do
    ont = ExtractedOntology.new()
    expect{ont.rdf_xml}.to raise_error
  end
end
