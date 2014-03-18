class CreateOntologiesPatterns < ActiveRecord::Migration
  def change
    create_table :ontologies_patterns, :id => false do |t|
      t.integer :ontology_id
      t.integer :pattern_id
    end
  end
end
