FactoryGirl.define do
  factory :simple_correspondence do
    entity1 "http://example.org/ontology5/myType1"
    entity2 "http://example.org/ontology6/myType2"
    measure "1.0"
    relation "="
    onto1 {FactoryGirl.create(:ontology, :url => "http://example.org/ontology5")}
    onto2 {FactoryGirl.create(:ontology, :url => "http://example.org/ontology6")}
  end
end
