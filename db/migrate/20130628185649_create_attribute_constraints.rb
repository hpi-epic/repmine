class CreateAttributeConstraints < ActiveRecord::Migration
  def change
    create_table :attribute_constraints do |t|
      t.references :node
      t.string :attribute_name
      t.string :value
      t.string :operator
      t.timestamps
    end
  end
end
