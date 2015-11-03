require 'rails_helper'

RSpec.describe Aggregation, :type => :model do
  it "should be able to create a clone for a different repository" do
    aggr = FactoryGirl.create(:aggregation)
    repo = FactoryGirl.create(:repository)
    target_node = FactoryGirl.create(:node, ontology: repo.ontology)
    PatternElementMatch.create(:matched_element => aggr.pattern_element, :matching_element => target_node)

    aggr_clone = aggr.clone_for(repo)
    assert_equal target_node, aggr_clone.pattern_element
  end
end
