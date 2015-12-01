require 'rails_helper'

RSpec.describe MetricNode, :type => :model do

  before(:each) do
    source_pattern = FactoryGirl.create(:node_only_pattern)
    @node = source_pattern.nodes.first
    @agg = FactoryGirl.create(:aggregation, pattern_element: @node)
    @mn = FactoryGirl.create(:metric_node, aggregation: @agg)
    @repo = FactoryGirl.create(:repository)
    target_pattern = FactoryGirl.create(:pattern, ontologies: [@repo.ontology])
    @ac = target_pattern.attribute_constraints.last
    PatternElementMatch.create(matched_element: @node, matching_element: @ac)
  end

  it "should create a proper qualified name for a metric node" do
    expect(@mn.qualified_name(nil)).to eq("#{@mn.id}_#{@node.speaking_name}")
    t_agg = @agg.translated_to(@repo)
    expect(@mn.qualified_name(@repo)).to eq("#{@mn.id}_#{@ac.speaking_name}")
  end

  it "should provide exactly the same amount of translated aggregations for each repository" do
    @mn.aggregations << @agg
    expect(@mn.translated_aggregations(nil)).to eq([@agg])
    t_agg = @agg.translated_to(@repo)
    expect(@mn.translated_aggregations(@repo)).to eq([t_agg])
  end
end
