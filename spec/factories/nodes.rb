# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :node do
    transient {ac_count 1}
    transient {rc_count 1}
    ontology
    rdf_type "http://example.org/node"

    after(:create) do |node, evaluator|
      create_list(:relation_constraint, evaluator.rc_count, source: node, target: node, pattern: node.pattern, ontology: node.ontology)
      create_list(:attribute_constraint, evaluator.ac_count, node: node, pattern: node.pattern, ontology: node.ontology)
    end
  end

  factory :plain_node, :class => Node do
    rdf_type "http://example.org/node"
    ontology
  end
end
