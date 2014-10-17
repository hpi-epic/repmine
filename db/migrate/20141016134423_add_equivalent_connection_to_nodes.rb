class AddEquivalentConnectionToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :equivalent_to, :integer
    add_index :nodes, :equivalent_to
  end
end
