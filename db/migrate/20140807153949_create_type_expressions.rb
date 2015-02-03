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
  end
end
