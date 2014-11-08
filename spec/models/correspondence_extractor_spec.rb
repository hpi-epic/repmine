require 'rails_helper'

RSpec.describe CorrespondenceExtractor, :type => :model do
  
  before(:each) do
    @ce = CorrespondenceExtractor.new()    
  end
  
  it "should figure out a simple pattern" do 
    @pattern = FactoryGirl.create(:node_only_pattern)
    @ce.classify!(@pattern.rdf)
    assert_equal 1, select_classification(@ce, @pattern, CorrespondenceExtractor::SG).size
  end
  
  it "should not think a multi-element pattern is simple" do 
    @pattern = FactoryGirl.create(:pattern)
    @ce.classify!(@pattern.rdf)
    assert_equal 0, select_classification(@ce, @pattern, CorrespondenceExtractor::SG).size
  end
  
  it "should find a n-r-n pattern" do 
    @pattern = FactoryGirl.create(:empty_pattern)
    n1 = FactoryGirl.create(:plain_node, :pattern => @pattern)
    n2 = FactoryGirl.create(:plain_node, :pattern => @pattern)
    r = FactoryGirl.create(:relation_constraint, :source => n1, :target => n2, :type_expression => FactoryGirl.create(:type_expression_rel1))
    @ce.classify!(@pattern.rdf)
    assert_equal 1, select_classification(@ce, @pattern, CorrespondenceExtractor::N_RC_N).size
  end
  
  def select_classification(ce, pattern, classification)
    ce.rule_engine.select(pattern.resource, CorrespondenceExtractor::C_PROP, classification)
  end
  
end
