require 'rails_helper'

RSpec.describe Metric, :type => :model do
  
  it "should return all columns of the result set" do
    metric = FactoryGirl.create(:metric)
    mn1 = MetricOperatorNode.create(:operator_cd => 1)
    pattern = FactoryGirl.create(:pattern)
    mn2 = MetricNode.create(:measurable_id => pattern.id)
    mn2.aggregation = mn2.aggregations.create(:pattern_element_id => pattern.nodes.first.id, :operation => :sum, :alias_name => "Individual Contribution")
    mn2.aggregations.create(:pattern_element_id => pattern.attribute_constraints.last.id, :operation => :group_by)
    
    mn3 = MetricNode.create(:measurable_id => pattern.id)
    mn3.aggregation = mn3.aggregations.create(:pattern_element_id => pattern.nodes.first.id, :operation => :sum, :alias_name => "All Contribution")
    
    mn1.children << mn2
    mn1.children << mn3
    metric.metric_nodes = [mn1,mn2,mn3]
    
    ac_name = pattern.attribute_constraints.last.speaking_name
    assert_empty ["All Contribution", "Individual Contribution", ac_name, "Ownership"] - metric.result_columns()
  end
  
  it "should determine an ambiguous naming" do
    metric = FactoryGirl.create(:metric)
    pattern = FactoryGirl.create(:pattern)
    mn2 = MetricNode.create(:measurable_id => pattern.id)
    mn2.aggregation = mn2.aggregations.create(:pattern_element_id => pattern.nodes.first.id, :operation => :sum, :alias_name => "All Contribution")
    mn3 = MetricNode.create(:measurable_id => pattern.id)
    mn3.aggregation = mn3.aggregations.create(:pattern_element_id => pattern.nodes.first.id, :operation => :sum, :alias_name => "All Contribution")
    metric.metric_nodes = [mn2,mn3]
    assert metric.is_ambiguous?
  end
  
  it "should figure out all columns of the result set for a metric translated to another repository" do
  
  end
end