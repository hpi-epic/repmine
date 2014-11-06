FactoryGirl.define do
  factory :ontology_correspondence do
    input_elements {create_list :pattern_element, 1, :type_expression => FactoryGirl.create(:type_expression, :rdf_override => "http://example.org/myType1")}
    output_elements {create_list :pattern_element, 1, :type_expression => FactoryGirl.create(:type_expression, :rdf_override => "http://example.org/myType2")}    
    measure "1.0"
    relation "="
    association :input_ontology, :factory => :ontology, :url => "http://example.org/ontology5"
    association :output_ontology, :factory => :ontology, :url => "http://example.org/ontology6"
  end
end