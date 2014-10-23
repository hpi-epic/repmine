class CreateTypeExpressions < ActiveRecord::Migration
  def change
    create_table :type_expressions do |t|
      t.string :operator
      t.string :rdf_type
      t.references :pattern_element
      t.timestamps
    end
  end
end
