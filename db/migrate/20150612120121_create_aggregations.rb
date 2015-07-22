class CreateAggregations < ActiveRecord::Migration
  def change
    create_table :aggregations do |t|
      t.references :pattern_element
      t.references :metric_node
      t.string :column_name
      t.integer :operation_cd
      t.timestamps
    end
    
    add_index :aggregations, :pattern_element_id
    add_index :aggregations, :metric_node_id    
  end
end