FactoryGirl.define do
  factory :complex_correspondence do
    entity1 "http://example.org/ontology5/myType1"
    entity2 {FactoryGirl.create(:pattern).pattern_elements}
    measure "1.0"
    relation "="
    onto1 {FactoryGirl.create(:ontology)}
    onto2 {FactoryGirl.create(:ontology)}
  end

  factory :hardway_complex, :class => "ComplexCorrespondence" do
    entity2 "http://example.org/ontology5/myType1"
    entity1 {FactoryGirl.create(:pattern).pattern_elements}
    measure "1.0"
    relation "="
    onto1 {FactoryGirl.create(:ontology)}
    onto2 {FactoryGirl.create(:ontology)}
  end

  factory :m_to_n_complex, :class => "ComplexCorrespondence" do
    entity1 {FactoryGirl.create(:n_r_n_pattern).pattern_elements}
    entity2 {FactoryGirl.create(:n_r_n_pattern).pattern_elements}
    measure "1.0"
    relation "="
    onto1 {FactoryGirl.create(:ontology)}
    onto2 {FactoryGirl.create(:ontology)}
  end
end
