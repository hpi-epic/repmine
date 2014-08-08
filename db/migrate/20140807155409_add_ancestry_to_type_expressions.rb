class AddAncestryToTypeExpressions < ActiveRecord::Migration
  def change
    add_column :type_expressions, :ancestry, :string
    add_index :type_expressions, :ancestry
  end
end
