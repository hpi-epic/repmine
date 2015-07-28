class CreateMeasurables < ActiveRecord::Migration
  def change
    create_table :measurables do |t|
      t.string :name
      t.text :description
      t.string :type
      t.integer :pattern_id
      t.text :description
      t.string :name
      t.string :type
      t.timestamps
    end
    add_index :measurables, :pattern_id
  end
end
