class CreatePatternElements < ActiveRecord::Migration
  def change
    create_table :pattern_elements do |t|
      # general properties and foreign keys
      t.string :type
      t.references :pattern
      t.references :equivalent
      # attribute constraint stuff
      t.references :node
      t.string :value
      t.string :operator
      # relation constraint stuff
      t.string :min_cardinality
      t.string :max_cardinality
      t.string :min_path_length
      t.string :max_path_length  
      t.integer :x, :default => 0
      t.integer :y, :default => 0
      t.integer :source_id
      t.integer :target_id      
      # node stuff
      t.timestamps
    end
  end
end
