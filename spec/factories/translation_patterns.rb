FactoryGirl.define do
  factory :translation_pattern do
    name "sample translation"
    description "an empty translation pattern"
    pattern {FactoryGirl.create(:pattern)}
    ontologies{[FactoryGirl.create(:ontology)]}
  end
end