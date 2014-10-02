require 'rails_helper'

RSpec.describe CorrespondenceExtractor, :type => :model do
  
  before(:each) do
    @ce = CorrespondenceExtractor.new
  end
  
  it "should figure out a simple pattern" do 
    @pattern = FactoryGirl.create(:node_only_pattern)
    @ce.extract_correspondences!(@pattern.rdf)
    assert_equal 1, @ce.rule_engine.select(@pattern.resource, "classification", "simple").size
  end
  
  it "should not think a multi-element pattern is simple" do 
    @pattern = FactoryGirl.create(:pattern)
    @ce.extract_correspondences!(@pattern.rdf)
    assert_equal 0, @ce.rule_engine.select(@pattern.resource, "classification", "simple").size
    # TODO: figure out just what the pattern really is...
  end
  
end
