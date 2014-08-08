class CreateTypeExpressions < ActiveRecord::Migration
  def change
    create_table :type_expressions do |t|
      t.string :operator
      t.string :rdf_type
      t.references :node
      t.timestamps
    end
  end
end
