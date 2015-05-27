# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :attribute_constraint do
    association :type_expression, :factory => :type_expression, :rdf_override => "http://example.org/attribute"
    operator AttributeConstraint::OPERATORS[:equals]
    value "hello world"
  end
end
