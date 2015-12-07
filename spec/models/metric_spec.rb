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
    build_simple_metric()

    results = {
      @mn1 => [{"NodeGroup" => "node1","AcSum" => 5},{"NodeGroup" => "node2","AcSum" => 10}],
      @mn2 => [{"NodeGroup" => "node1","AcAvg" => 2.5},{"NodeGroup" => "node2","AcAvg" => 0}]
    }

    complete_results, csv = @metric.process_results(results)
    expect(complete_results.size).to eq(2)
    expect(complete_results.first[@metric.name]).to eq(2)
    expect(complete_results.last[@metric.name]).to eq(0)
  end

  it "should detect overlapping headers in the results" do
    expect(@metric.overlapping_result_headers({a: [{:b => 2, :c => 3}], :b => [{:b => 5, :f => 4}]})).to eq([:b])
    expect(@metric.overlapping_result_headers({a: [{:d => 2, :c => 3}], :b => [{:b => 5, :f => 4}]})).to be_empty
    expect(@metric.overlapping_result_headers({a: [{x1: 2, y: 3, z: 4}, {x1: 4, y: 34, z: 34}], b: [{x1: 2, x2: 3}, {x1: 4, x2: 5}]})).to eq([:x1])
  end

  it "should properly combine results from metrics with other stuff" do
    build_simple_metric()
    mmn = MetricMetricNode.create!(:measurable_id => @metric.id)
    meta_metric = FactoryGirl.create(:metric, name: "AdvancedOwnership")
    mmn2 = MetricNode.create!(:measurable_id => @pattern.id)
    agg3 = mmn2.aggregations.create!(:pattern_element_id => @pattern.nodes.first.id, operation: :group_by, alias_name: "NodeGroup")
    mmn2.aggregation = mmn2.aggregations.create!(:pattern_element_id => @pattern.attribute_constraints.first.id, operation: :sum, alias_name: "AcSummm")

    meta_metric.metric_nodes = [mmn, mmn2]

    results = {
      mmn => [{"NodeGroup" => "node1","#{@mn1.id}_AcSum" => 5, "#{@mn2.id}_AcAvg" => 10, "Ownership" => 50}],
      mmn2 => [{"NodeGroup" => "node1","AcSummm" => 2.5}]
    }

    complete_results, csv = meta_metric.process_results(results)
    expect(complete_results.size).to eq(1)
    expect(complete_results.first["AdvancedOwnership"]).to be_nil
    expect(complete_results.first["NodeGroup"]).to eq("node1")
    expect(complete_results.first["#{mmn.id}_Ownership"]).to eq(50)

    # now let's add a calculation
    mopn = MetricOperatorNode.create(:operator_cd => MetricOperatorNode.operators[:add])
    mmn.parent = mopn
    mmn.aggregation = mmn.aggregations.create!(column_name: "Ownership", operation: :avg, alias_name: "AvgOwnership")
    mmn.save!
    mmn2.parent = mopn
    mmn2.save
    meta_metric.metric_nodes << mopn

    results[mmn] << {"NodeGroup" => "node2","#{@mn1.id}_AcSum" => 10, "#{@mn2.id}_AcAvg" => 20, "Ownership" => 100}
    results[mmn2] << {"NodeGroup" => "node2","AcSummm" => 5}
    results[mmn] = mmn.get_aggregates(mmn.group_results(results[mmn]))
    complete_results, csv = meta_metric.process_results(results)
    # one result per "NodeGroup"
    expect(complete_results.size).to eq(2)
    # once 75 + 2.5 and the second is 75 + 5
    expect(complete_results.first["AdvancedOwnership"]).to eq(77.5)
    expect(complete_results.last["AdvancedOwnership"]).to eq(80)
    # 4 elements per result: NodeGroup, AcSumm, AvgOwnership, AdvancedOwnership
    expect(complete_results.all?{|res| res.size == 4}).to be(true)
  end

  it "should ask all its leaf nodes whether it is executable" do
    build_simple_metric()
    Pattern.any_instance.stub(:executable_on?){false}
    expect(@metric.executable_on?(@repo)).to be(false)
  end

  it "should start threads for all leaf nodes and call process results for the created hash" do
    build_simple_metric()
    MetricNode.any_instance.stub(:results_on){[{"happy" => "hunting"}]}
    @metric.stub(:process_results){|input| input}
    results = @metric.run_on_repository(@repo)
    expect(results.size).to eq(2)
  end

  def build_simple_metric
    @repo = FactoryGirl.create(:repository)
    @pattern = FactoryGirl.create(:pattern, ontologies: [@repo.ontology])
    @mn1 = MetricNode.create(:measurable_id => @pattern.id)
    @mn2 = MetricNode.create(:measurable_id => @pattern.id)
    @agg1 = @mn1.aggregations.create!(:pattern_element_id => @pattern.nodes.first.id, operation: :group_by, alias_name: "NodeGroup")
    @mn1.aggregation = @mn1.aggregations.create!(:pattern_element_id => @pattern.attribute_constraints.first.id, operation: :sum, alias_name: "AcSum")
    @agg2 = @mn2.aggregations.create!(:pattern_element_id => @pattern.nodes.first.id, operation: :group_by, alias_name: "NodeGroup")
    @mn2.aggregation = @mn2.aggregations.create!(:pattern_element_id => @pattern.attribute_constraints.first.id, operation: :avg, alias_name: "AcAvg")
    @mon = MetricOperatorNode.create(operator_cd: MetricOperatorNode.operators[:divide])

    @mn1.parent = @mon
    @mn2.parent = @mon
    @mn1.save
    @mn2.save
    @metric.metric_nodes = [@mon,@mn1,@mn2]
  end
end