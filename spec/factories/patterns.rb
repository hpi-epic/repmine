FactoryGirl.define do
  factory :pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    nodes {create_list(:node, 1)}
    ontologies {create_list :ontology, 1}
  end
  
  factory :node_only_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    nodes {create_list(:plain_node, 1)}
    ontologies {create_list :ontology, 1}    
  end
  
  factory :empty_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern without anything"
    ontologies {create_list :ontology, 1}
  end
end