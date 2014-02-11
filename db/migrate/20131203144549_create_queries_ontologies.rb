class CreateQueriesOntologies < ActiveRecord::Migration
  def change
    create_table :ontologies_queries, :id => false do |t|
      t.integer :ontology_id
      t.integer :query_id
    end
  end
end
