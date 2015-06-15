class CreateAggregations < ActiveRecord::Migration
  def change
    create_table :aggregations do |t|
      t.references :pattern_element
      t.integer :operation_cd
      t.timestamps
    end
  end
end
