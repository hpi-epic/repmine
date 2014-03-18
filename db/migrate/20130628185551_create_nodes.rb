class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.references :pattern
      t.string :rdf_type
      t.boolean :root_node
      t.integer :x, :default => 0
      t.integer :y, :default => 0
      t.timestamps
    end
  end
end
