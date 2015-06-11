# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :node do
    transient {ac_count 1}
    transient {rc_count 1}
    ontology
    association :type_expression, :factory => :type_expression, :rdf_override => "http://example.org/node"

    after(:create) do |node, evaluator|
      create_list(:relation_constraint, evaluator.rc_count, source: node, target: node, pattern: node.pattern)
      create_list(:attribute_constraint, evaluator.ac_count, node: node, pattern: node.pattern)
    end
  end

  factory :plain_node, :class => Node do
    association :type_expression, :factory => :type_expression, :rdf_override => "http://example.org/node"
    ontology
  end
end
