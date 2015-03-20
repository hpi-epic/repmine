# == Schema Information
#
# Table name: repositories
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  db_name       :string(255)
#  db_username   :string(255)
#  db_password   :string(255)
#  host          :string(255)
#  port          :integer
#  description   :text
#  ontology_id   :integer
#  type          :string(255)
#  rdbms_type_cd :integer
#

FactoryGirl.define do
  factory :repository do
    name "sample_repo"
    description "a simple repository without db connection"

    factory :rdf_repository, class: RdfRepository, parent: :repository do |u|
      type "RdfRepository"
    end

    factory :neo4j_repository, class: Neo4jRepository, parent: :repository do |u|
      type "Neo4jRepository"
    end

  end


end
