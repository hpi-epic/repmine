# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :relation_constraint do
    association :type_expression, :factory => :type_expression, :rdf_override => "http://example.org/relation"  
  end
end
