class CreateAggregations < ActiveRecord::Migration
  def change
    create_table :aggregations do |t|
      t.boolean :distinct, default: false
      t.references :pattern_element
      t.references :metric_node
      t.references :ontology
      t.references :aggregation
      t.integer :operation_cd
      t.string :column_name
      t.string :alias_name
      t.string :type
      t.timestamps
    end

    add_index :aggregations, :pattern_element_id
    add_index :aggregations, :aggregation_id
    add_index :aggregations, :metric_node_id
    add_index :aggregations, :ontology_id
  end
end