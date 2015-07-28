class CreateOntologiesPatterns < ActiveRecord::Migration
  def change
    create_table :ontologies_patterns do |t|
      t.integer :ontology_id
      t.integer :pattern_id
    end
    add_index :ontologies_patterns, :ontology_id
    add_index :ontologies_patterns, :pattern_id
  end
end
