class CreatePatternElements < ActiveRecord::Migration
  def change
    create_table :pattern_elements do |t|
      # general properties and foreign keys
      t.string :type
      t.timestamps
      t.references :ontology
      t.references :pattern
      # attribute constraint
      t.references :node
      t.string :value
      t.string :operator
      t.boolean :virtual, :default => false
      # relation constraint
      t.string :min_cardinality
      t.string :max_cardinality
      t.string :min_path_length
      t.string :max_path_length
      t.integer :source_id
      t.integer :target_id
      # node
      t.integer :x, :default => 0
      t.integer :y, :default => 0
    end

    add_index :pattern_elements, :ontology_id
    add_index :pattern_elements, :pattern_id
  end
end
