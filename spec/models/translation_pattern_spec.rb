require 'rails_helper'

RSpec.describe TranslationPattern, :type => :model do
  
  before(:each) do
    Pattern.any_instance.stub(:initialize_repository! => true)
    Pattern.any_instance.stub(:match_concepts => [])    
    @pattern = FactoryGirl.create(:pattern)
    @ontology = FactoryGirl.create(:ontology, :url => "http://example.org/ontology2")
  end
  
  it "should create an empty pattern for all unmatched concepts" do
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_empty @tp.nodes
    assert_empty @tp.pattern_elements
  end
  
  it "should create a node for each matched concept" do
    # let's translate the first node
    type = @pattern.nodes.first.rdf_type
    correspondence = OntologyCorrespondence.new(type, type + "_matched")
    Pattern.any_instance.stub(:match_concepts => [correspondence])
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_not_empty @tp.nodes
    assert_equal type + "_matched", @tp.nodes.first.rdf_type
    assert_equal @pattern.nodes.first, @tp.nodes.first.equivalent
    assert_equal 1, @pattern.nodes.first.equivalents.size
  end
  
end