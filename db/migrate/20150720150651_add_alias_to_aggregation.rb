class AddAliasToAggregation < ActiveRecord::Migration
  def change
    add_column :aggregations, :alias_name, :string
  end
end
