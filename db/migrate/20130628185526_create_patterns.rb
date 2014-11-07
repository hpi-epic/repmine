class CreatePatterns < ActiveRecord::Migration
  def change
    create_table :patterns do |t|
      t.string :name
      t.text :description
      t.integer :ontology_id
      t.timestamps
    end
    add_index :patterns, :ontology_id    
  end
end
