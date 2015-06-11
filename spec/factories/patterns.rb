# == Schema Information
#
# Table name: patterns
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  ontology_id :integer
#  type        :string(255)
#  pattern_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryGirl.define do
  factory :pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    transient{node_count 1}
    ontologies{[FactoryGirl.create(:ontology)]}
    after(:create) do |pattern, evaluator|
      create_list(:node, evaluator.node_count, pattern: pattern)
    end
  end

  factory :node_only_pattern, :class => Pattern do
    name "sample pattern"
    description "a simple pattern with a node, a relation constraint, and an attribute constraint"
    ontologies{[FactoryGirl.create(:ontology)]}
    transient{node_count 1}
    after(:create) do |pattern, evaluator|
      create_list(:plain_node, evaluator.node_count, pattern: pattern)
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
    pattern_elements{create_list :plain_node, 2}
    after(:create) do |pattern, evaluator|
      FactoryGirl.create(:relation_constraint, :source => pattern.nodes.first, :target => pattern.nodes.last)
    end
  end
end
