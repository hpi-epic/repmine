FactoryGirl.define do
  factory :pattern_element do
    association :type_expression, :factory => :type_expression, :rdf_override => "http://example.org/generic_element"
  end
end
