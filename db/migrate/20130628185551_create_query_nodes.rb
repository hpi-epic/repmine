class CreateQueryNodes < ActiveRecord::Migration
  def change
    create_table :query_nodes do |t|
      t.references :query
      t.string :rdf_type
      t.boolean :root_node
      t.timestamps
    end
  end
end
