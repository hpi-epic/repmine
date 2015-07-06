class CreateMetricNodes < ActiveRecord::Migration
  def change
    create_table :metric_nodes do |t|
      t.references :pattern
      t.references :aggregation
      t.string :ancestry
      t.integer :operator_cd
      t.integer :operation_cd
      t.references :metric
      t.integer :x, :default => 0
      t.integer :y, :default => 0
      t.timestamps
    end
    
    add_index :metric_nodes, :ancestry  
    add_index :metric_nodes, :pattern_id       
    add_index :metric_nodes, :aggregation_id           
  end
end
