class RemoveRdfTypeFieldFromNodes < ActiveRecord::Migration
  def up
    remove_column :nodes, :rdf_type
  end

  def down
    add_column :nodes, :rdf_type, :string
  end
end
