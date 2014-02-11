class CreateQueryTimeConstraints < ActiveRecord::Migration
  def change
    create_table :query_time_constraints do |t|
      t.integer :from_id
      t.integer :to_id
      t.decimal :min_time
      t.decimal :max_time
      t.boolean :return_timepspan
      t.string :variable_name
      t.timestamps
    end
  end
end
