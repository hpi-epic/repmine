require 'rails_helper'

RSpec.describe CorrespondenceExtractor, :type => :model do
  
  before(:each) do
    @ce = CorrespondenceExtractor.new
    Pattern.any_instance.stub(:initialize_repository! => true)
  end
  
  it "should figure out a simple pattern" do 
    @pattern = FactoryGirl.create(:node_only_pattern)
    @ce.extract_correspondences!(@pattern.rdf)
    assert_equal 1, select_classification(@ce, @pattern, CorrespondenceExtractor::SG).size
  end
  
  it "should not think a multi-element pattern is simple" do 
    @pattern = FactoryGirl.create(:pattern)
    @ce.extract_correspondences!(@pattern.rdf)
    assert_equal 0, select_classification(@ce, @pattern, CorrespondenceExtractor::SG).size
    # TODO: figure out just what the pattern really is...
  end
  
  it "should find a n-r-n pattern" do 
    @pattern = FactoryGirl.create(:empty_pattern)
    n1 = FactoryGirl.create(:plain_node, :pattern => @pattern)
    n2 = FactoryGirl.create(:plain_node, :pattern => @pattern)
    r = FactoryGirl.create(:relation_constraint, :source => n1, :target => n2, :type_expression => FactoryGirl.create(:type_expression_rel1))
    @ce.extract_correspondences!(@pattern.rdf)
    assert_equal 1, select_classification(@ce, @pattern, CorrespondenceExtractor::N_RC_N).size    
    r2 = FactoryGirl.create(:relation_constraint, :source => n2, :target => n1, :type_expression => FactoryGirl.create(:type_expression_rel2))
    @ce.extract_correspondences!(@pattern.rdf)    
    #assert_equal 2, select_classification(@ce, @pattern, CorrespondenceExtractor::N_RC_N).size        
  end
  
  def select_classification(ce, pattern, classification)
    ce.rule_engine.select(pattern.resource, CorrespondenceExtractor::C_PROP, classification)
  end
  
end
