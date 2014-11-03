FactoryGirl.define do
  factory :ontology_correspondence do
    entity1 "http://example.org/entity1"
    entity2 "http://example.org/entity2"
    measure "1.0"
    relation "="
    ontology1 "http://example.org/ontology1"
    ontology2 "http://example.org/ontology2"
  end
end