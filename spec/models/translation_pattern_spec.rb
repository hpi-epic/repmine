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
  
  it "should transfer pattern elements to the translation pattern for each matched concept" do
    # let's translate the first node
    correspondence = FactoryGirl.create(:ontology_correspondence)
    correspondence.input_elements << @pattern.nodes.first
    Pattern.any_instance.stub(:match_concepts => [correspondence])
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal 1, @tp.pattern_elements.size
    assert_equal correspondence.entity2, @tp.pattern_elements.first
  end
  
end