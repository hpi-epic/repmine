# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :node do
    attribute_constraints {create_list :attribute_constraint, 1}
    transient {rc_count 1}
    type_expression
    
    after(:create) do |node, evaluator|
      create_list(:relation_constraint, evaluator.rc_count, source: node, target: node)
    end
  end
  
  factory :plain_node, :class => Node do 
    type_expression
  end
end
