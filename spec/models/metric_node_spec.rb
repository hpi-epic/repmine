require 'rails_helper'

RSpec.describe MetricNode, :type => :model do

  before(:each) do
    source_pattern = FactoryGirl.create(:node_only_pattern)
    @node = source_pattern.nodes.first
    @agg = FactoryGirl.create(:aggregation, pattern_element: @node, alias_name: "Node")
    @mn = FactoryGirl.create(:metric_node, aggregation: @agg)
    @repo = FactoryGirl.create(:repository)
    target_pattern = FactoryGirl.create(:pattern, ontologies: [@repo.ontology])
    @ac = target_pattern.attribute_constraints.last
    PatternElementMatch.create(matched_element: @node, matching_element: @ac)
  end

  it "should create a proper qualified name for a metric node" do
    expect(@mn.qualified_name()).to eq("#{@mn.id}_Node")
  end

  it "should provide exactly the same amount of translated aggregations for each repository" do
    @mn.aggregations << @agg
    expect(@mn.translated_aggregations(nil)).to eq([@agg])
    t_agg = @agg.translated_to(@repo)
    expect(@mn.translated_aggregations(@repo)).to eq([t_agg])
  end

  it "should create a fancy calculation template" do
    @agg.update_attributes(operation: :avg)
    agg2 = FactoryGirl.create(:aggregation, pattern_element: @node, operation: :sum, alias_name: "Node")
    mn2 = FactoryGirl.create(:metric_node, aggregation: agg2)
    op_node = FactoryGirl.create(:metric_operator_node, operator_cd: MetricOperatorNode.operators[:multiply])
    @mn.parent = op_node
    @mn.save
    mn2.parent = op_node
    mn2.save
    expect(op_node.children.size).to eq(2)
    expect(op_node.calculation_template(@repo)).to eq("(#{@mn.qualified_name}*#{mn2.qualified_name})")
  end
end
