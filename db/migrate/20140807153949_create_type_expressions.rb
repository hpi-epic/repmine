class CreateTypeExpressions < ActiveRecord::Migration
  def change
    create_table :type_expressions do |t|
      t.string :operator
      t.string :rdf_type
      t.references :pattern_element
      t.string :ancestry
      t.timestamps
    end
    add_index :type_expressions, :ancestry
    add_index :type_expressions, :pattern_element_id    
  end
end
