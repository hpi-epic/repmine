require 'rails_helper'

RSpec.describe CorrespondenceExtractor, :type => :model do

  before(:each) do
    @ce = CorrespondenceExtractor.new()
  end

  it "should figure out a simple pattern" do
    @pattern = FactoryGirl.create(:node_only_pattern)
    c_engine = @ce.classify(@pattern)
    assert_equal 1, select_classification(c_engine, @pattern, CorrespondenceExtractor::SG).size
  end

  it "should not think a multi-element pattern is simple" do
    @pattern = FactoryGirl.create(:pattern)
    c_engine = @ce.classify(@pattern)
    assert_equal 0, select_classification(c_engine, @pattern, CorrespondenceExtractor::SG).size
  end

  it "should find a n-r-n pattern" do
    @pattern = FactoryGirl.create(:empty_pattern)
    n1 = FactoryGirl.create(:plain_node, :pattern => @pattern)
    n2 = FactoryGirl.create(:plain_node, :pattern => @pattern)
    r = FactoryGirl.create(:relation_constraint, :source => n1, :target => n2, :type_expression => FactoryGirl.create(:type_expression_rel1))
    c_engine = @ce.classify(@pattern)
    assert_equal 1, select_classification(c_engine, @pattern, CorrespondenceExtractor::N_RC_N).size
  end

  it "should be able to assert a new correspondence if only one element of two n-r-n graphs is missing" do
    @pattern1 = FactoryGirl.create(:n_r_n_pattern)
    @pattern2 = FactoryGirl.create(:n_r_n_pattern)
    OntologyMatcher.any_instance.stub(:add_correspondence! => true)
    oc1 = OntologyCorrespondence.for_elements!([@pattern1.nodes.first], [@pattern2.nodes.first])
    oc2 = OntologyCorrespondence.for_elements!([@pattern1.nodes.last], [@pattern2.nodes.last])
    assert_equal 2, OntologyCorrespondence.count
    @ce.detect_missing_correspondences!(@pattern1, @pattern2)
    assert_equal 3, OntologyCorrespondence.count
  end

  def select_classification(rule_engine, pattern, classification)
    rule_engine.select(pattern.resource, CorrespondenceExtractor::C_PROP, classification)
  end

end
