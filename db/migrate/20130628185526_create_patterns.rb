class CreatePatterns < ActiveRecord::Migration
  def change
    create_table :patterns do |t|
      t.string :name
      t.text :description
      t.integer :ontology_id
      t.string :type
      t.integer :pattern_id
      t.timestamps
    end
    add_index :patterns, :ontology_id
    add_index :patterns, :pattern_id          
  end
end
