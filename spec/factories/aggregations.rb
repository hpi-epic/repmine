FactoryGirl.define do
  factory :aggregation do
    operation :group_by
    pattern_element {FactoryGirl.create(:node)}
    metric_node{FactoryGirl.create(:metric_node)}
    alias_name "NodeGroup"
  end

  factory :count_aggregation, :class => Aggregation do
    operation :count
    alias_name "NodeCount"
  end

end
