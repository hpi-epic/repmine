FactoryGirl.define do
  factory :pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    transient{node_count 1}
    ontologies {create_list :ontology, 1}
    after(:create) do |pattern, evaluator|
      create_list(:node, evaluator.node_count, pattern: pattern)
    end
  end
  
  factory :node_only_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    ontologies {create_list :ontology, 1}    
    transient{node_count 1}    
    after(:create) do |pattern, evaluator|
      create_list(:plain_node, evaluator.node_count, pattern: pattern)
    end    
  end
  
  factory :empty_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern without anything"
    ontologies {create_list :ontology, 1}
  end
end