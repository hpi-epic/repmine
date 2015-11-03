FactoryGirl.define do
  factory :repository do
    name "sample_repo"
    description "a simple repository without db connection"

    factory :rdf_repository, class: RdfRepository, parent: :repository do |u|
      type "RdfRepository"
      ontology_url "http://example.org/test_ontology/"
    end

    factory :neo4j_repository, class: Neo4jRepository, parent: :repository do |u|
      type "Neo4jRepository"
    end

  end
end
