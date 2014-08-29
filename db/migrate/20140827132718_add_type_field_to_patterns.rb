class AddTypeFieldToPatterns < ActiveRecord::Migration
  def change
    add_column :patterns, :type, :string
    add_column :patterns, :target_ontology_id, :integer
    add_column :patterns, :pattern_id, :integer
    add_index :patterns, :pattern_id
    add_index :patterns, :target_ontology_id    
  end
end
