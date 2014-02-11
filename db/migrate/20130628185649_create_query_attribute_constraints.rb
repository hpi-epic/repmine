class CreateQueryAttributeConstraints < ActiveRecord::Migration
  def change
    create_table :query_attribute_constraints do |t|
      t.references :query_node
      t.string :attribute_name
      t.string :value
      t.string :operator
      t.timestamps
    end
  end
end
