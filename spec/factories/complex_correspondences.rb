FactoryGirl.define do
  factory :complex_correspondence do
    entity1 "http://example.org/ontology5/myType1"
    entity2 {FactoryGirl.create(:pattern)}
    measure "1.0"
    relation "="
    onto1 {FactoryGirl.create(:ontology, :url => "http://example.org/ontology5")}
    onto2 {FactoryGirl.create(:ontology, :url => "http://example.org/ontology6")}
  end
end
