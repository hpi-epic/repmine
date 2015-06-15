FactoryGirl.define do
  factory :aggregation do
    operation :group_by
  end
  
  factory :count_aggregation, :class => Aggregation do
    operation :count
  end

end
