require 'rails_helper'

RSpec.describe Metric, :type => :model do

  before(:each) do
    @metric = FactoryGirl.create(:metric)
  end

  it "should return all columns of the result set" do

    mn1 = MetricOperatorNode.create(:operator_cd => 1)
    pattern = FactoryGirl.create(:pattern)
    mn2 = MetricNode.create(:measurable_id => pattern.id)
    mn2.aggregation = mn2.aggregations.create!(:pattern_element_id => pattern.nodes.first.id, :operation => :sum, :alias_name => "IndividualContribution")
    mn2.aggregations.create!(:pattern_element_id => pattern.attribute_constraints.last.id, :operation => :group_by, alias_name: "AcGroup")

    mn3 = MetricNode.create(:measurable_id => pattern.id)
    mn3.aggregation = mn3.aggregations.create(:pattern_element_id => pattern.nodes.first.id, :operation => :sum, :alias_name => "AllContribution")

    mn1.children << mn2
    mn1.children << mn3
    @metric.metric_nodes = [mn1,mn2,mn3]

    expect(["AllContribution", "IndividualContribution", "AcGroup", "Ownership"] - @metric.result_columns()).to be_empty
  end

  it "should determine which pattern a user needs to translate next to run this metric" do
    expect(@metric.first_unexecutable_pattern(nil)).to be_nil
    pattern = FactoryGirl.create(:pattern)
    mn1 = MetricNode.create(:measurable_id => pattern.id)
    @metric.metric_nodes = [mn1]
    Pattern.any_instance.stub(:executable_on?).with(anything()){true}
    expect(@metric.first_unexecutable_pattern(nil)).to be_nil
    repo = FactoryGirl.create(:repository)
    Pattern.any_instance.stub(:executable_on?).with(repo){false}
    expect(@metric.first_unexecutable_pattern(repo)).to eq(pattern)
    Pattern.any_instance.stub(:executable_on?).with(repo){true}
    expect(@metric.first_unexecutable_pattern(repo)).to be_nil
  end

  it "should create the proper node type" do
    expect(@metric.create_node(FactoryGirl.build(:pattern)).is_a?(MetricNode)).to be(true)
    expect(@metric.create_node(FactoryGirl.build(:metric)).is_a?(MetricMetricNode)).to be(true)
  end

  it "should properly combine results from two different metric nodes" do
    repo = FactoryGirl.create(:repository)
    pattern = FactoryGirl.create(:pattern, ontologies: [repo.ontology])
    mn1 = MetricNode.create(:measurable_id => pattern.id)
    mn2 = MetricNode.create(:measurable_id => pattern.id)
    agg1 = mn1.aggregations.create!(:pattern_element_id => pattern.nodes.first.id, operation: :group_by, alias_name: "NodeGroup")
    mn1.aggregation = mn1.aggregations.create!(:pattern_element_id => pattern.attribute_constraints.first.id, operation: :sum, alias_name: "AcSum")
    agg2 = mn2.aggregations.create!(:pattern_element_id => pattern.nodes.first.id, operation: :group_by, alias_name: "NodeGroup")
    mn2.aggregation = mn2.aggregations.create!(:pattern_element_id => pattern.attribute_constraints.first.id, operation: :avg, alias_name: "AcAvg")
    mon = MetricOperatorNode.create(operator_cd: MetricOperatorNode.operators[:multiply])

    mn1.parent = mon
    mn2.parent = mon
    mn1.save
    mn2.save
    @metric.metric_nodes = [mon,mn1,mn2]

    results = {
      mn1 => [{"NodeGroup" => "node1","AcSum" => 5},{"NodeGroup" => "node2","AcSum" => 10}],
      mn2 => [{"NodeGroup" => "node1","AcAvg" => 2.5},{"NodeGroup" => "node2","AcAvg" => 7.5}]
    }

    complete_results, csv = @metric.process_results(results, repo)
    expect(complete_results.size).to eq(2)
    expect(complete_results.first[@metric.name]).to eq(12.5)
    expect(complete_results.last[@metric.name]).to eq(75.0)
  end

  it "should detect overlapping headers in the results" do
    expect(@metric.overlapping_result_headers({a: [{:b => 2, :c => 3}], :b => [{:b => 5, :f => 4}]})).to eq([:b])
    expect(@metric.overlapping_result_headers({a: [{:d => 2, :c => 3}], :b => [{:b => 5, :f => 4}]})).to be_empty
  end
end