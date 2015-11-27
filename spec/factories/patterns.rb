FactoryGirl.define do
  factory :pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    transient{node_count 1}
    ontologies{[FactoryGirl.create(:ontology)]}
    after(:create) do |pattern, evaluator|
      evaluator.node_count.times do |nc|
        FactoryGirl.create(:node, pattern: pattern, ontology: pattern.ontologies.first, rdf_type: "http://example.org/node#{nc}")
      end
    end
  end

  factory :node_only_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    ontologies{[FactoryGirl.create(:ontology)]}
    transient{node_count 1}
    after(:create) do |pattern, evaluator|
      evaluator.node_count.times do |nc|
        FactoryGirl.create(:plain_node, pattern: pattern, ontology: pattern.ontologies.first, rdf_type: "http://example.org/node#{nc}")
      end
    end
  end

  factory :empty_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern without anything"
    ontologies{[FactoryGirl.create(:ontology)]}
  end

  factory :n_r_n_pattern, :class => Pattern do
    name "n-r-n"
    description "node-relation-node, that's it"
    ontologies{[FactoryGirl.create(:ontology)]}
    after(:create) do |pattern, evaluator|
      FactoryGirl.create(:plain_node, pattern: pattern, ontology: pattern.ontologies.first, rdf_type: "http://example.org/node1")
      FactoryGirl.create(:plain_node, pattern: pattern, ontology: pattern.ontologies.first, rdf_type: "http://example.org/node2")
      FactoryGirl.create(:relation_constraint, source: pattern.nodes.first, target: pattern.nodes.last, ontology: pattern.ontologies.first)
    end
  end
end
