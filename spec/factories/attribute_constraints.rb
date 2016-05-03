# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :attribute_constraint do
    rdf_type "http://example.org/attribute"
    operator AttributeConstraint::OPERATORS[:equals]
    value "hello world"
    ontology
  end
end
