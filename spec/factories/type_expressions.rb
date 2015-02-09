# == Schema Information
#
# Table name: type_expressions
#
#  id                 :integer          not null, primary key
#  operator           :string(255)
#  rdf_type           :string(255)
#  pattern_element_id :integer
#  ancestry           :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :type_expression do
    operator nil
    rdf_type nil
    transient do
      rdf_override "http://example.org/MyType"
    end
    after(:create) do |te, evaluator|
      te.children.create(:rdf_type => evaluator.rdf_override)
    end
  end

  factory :type_expression_plain, :class => TypeExpression do
    operator nil
    rdf_type "http://example.org/MyType"
  end

  factory :type_expression_2, :class => TypeExpression do
    operator nil
    rdf_type "http://example.org/MyType2"
  end

  factory :type_expression_3, :class => TypeExpression do
    operator nil
    rdf_type "http://example.org/MyType3"
  end

  factory :type_expression_rel1, :class => TypeExpression do
    operator nil
    rdf_type "http://example.org/rel1"
  end

  factory :type_expression_rel2, :class => TypeExpression do
    operator nil
    rdf_type "http://example.org/rel2"
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
