class CreateRelationConstraints < ActiveRecord::Migration
  def change
    create_table :relation_constraints do |t|
      t.integer :source_id
      t.integer :target_id
      t.string :min_cardinality
      t.string :max_cardinality
      t.string :min_path_length
      t.string :max_path_length
      t.string :relation_type
      t.timestamps
    end
  end
end
