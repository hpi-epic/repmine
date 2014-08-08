# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :type_expression do
    operator nil
    rdf_type "http://example.org/MyType"
  end
  
  factory :type_expression_2, :class => TypeExpression do
    operator nil
    rdf_type "http://example.org/MyType2"
  end
  
  factory :type_expression_sup, :class => TypeExpression do
    operator OwlClass::SET_OPS[:sup]
    rdf_type nil
  end
  
  factory :type_expression_sub, :class => TypeExpression do
    operator OwlClass::SET_OPS[:sub]
    rdf_type nil
  end
  
  factory :type_expression_not, :class => TypeExpression do
    operator OwlClass::SET_OPS[:not]
    rdf_type nil
  end
end
