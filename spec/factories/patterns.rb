FactoryGirl.define do
  factory :pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    nodes {build_list :node, 1}
    ontologies {build_list :ontology, 1}
  end
end