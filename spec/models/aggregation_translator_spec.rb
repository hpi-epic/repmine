require 'rails_helper'

RSpec.describe AggregationTranslator, :type => :model do

  it "should find class by value thingies" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    target_node = FactoryGirl.create(:node, ontology: repo.ontology)
    attr_constr = FactoryGirl.create(:attribute_constraint, ontology: repo.ontology, node: target_node)
    agg_trans = AggregationTranslator.new
    agg_trans.load_to_engine!(aggr.pattern_element, [target_node, attr_constr])
    assert_equal target_node, agg_trans.substitute
  end

  it "should find c to c-r-c thingies" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    n1 = FactoryGirl.create(:node, ontology: repo.ontology)
    n2 = FactoryGirl.create(:node, ontology: repo.ontology)
    r1 = FactoryGirl.create(:relation_constraint, source: n1, target: n2)
    agg_trans = AggregationTranslator.new
    agg_trans.load_to_engine!(aggr.pattern_element, [n1, n2, r1])
    assert_equal n1, agg_trans.substitute
  end

  it "should simply return nil if it is unable to find something (read: not crash!)" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    target_node = FactoryGirl.create(:node, ontology: repo.ontology)
    also_target = FactoryGirl.create(:node, ontology: repo.ontology)
    agg_trans = AggregationTranslator.new
    agg_trans.load_to_engine!(aggr.pattern_element, [target_node, also_target])
    assert_equal nil, agg_trans.substitute
  end

end