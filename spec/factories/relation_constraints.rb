# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :relation_constraint do
    rdf_type "http://example.org/relation"
    ontology
  end
end
