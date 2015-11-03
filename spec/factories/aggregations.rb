FactoryGirl.define do
  factory :aggregation do
    operation :group_by
    pattern_element {FactoryGirl.create(:node)}
  end

  factory :count_aggregation, :class => Aggregation do
    operation :count
  end

end
