# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :node do
    attribute_constraints {create_list :attribute_constraint, 1}
    source_relation_constraints { create_list(:relation_constraint, 1) }
    target_relation_constraints { create_list(:relation_constraint, 1) }    
    type_expression
  end
end
