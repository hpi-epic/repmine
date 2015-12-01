require 'rails_helper'

RSpec.describe Aggregation, :type => :model do
  it "should be able to create a clone for a different repository" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    target_node = FactoryGirl.create(:node, ontology: repo.ontology)
    PatternElementMatch.create(:matched_element => aggr.pattern_element, :matching_element => target_node)

    aggr_clone = aggr.translated_to(repo)
    assert_equal target_node, aggr_clone.pattern_element
  end

  it "should store translated aggregations in the DB" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    target_node = FactoryGirl.create(:node, ontology: repo.ontology)

    PatternElementMatch.create(:matched_element => aggr.pattern_element, :matching_element => target_node)

    first_clone = aggr.translated_to(repo)
    expect(first_clone).to_not eq(aggr)
    second_clone = aggr.translated_to(repo)
    expect(second_clone).to eq(first_clone)
  end

  it "should call the substitutor" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    target_node = FactoryGirl.create(:node, ontology: repo.ontology)
    attr_constr = FactoryGirl.create(:attribute_constraint, ontology: repo.ontology, node: target_node)
    PatternElementMatch.create(:matched_element => aggr.pattern_element, :matching_element => target_node)
    PatternElementMatch.create(:matched_element => aggr.pattern_element, :matching_element => attr_constr)
    assert_equal target_node, aggr.translated_to(repo).pattern_element
  end

end
