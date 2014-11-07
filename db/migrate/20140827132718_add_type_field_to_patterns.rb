class AddTypeFieldToPatterns < ActiveRecord::Migration
  def change
    add_column :patterns, :type, :string
    add_column :patterns, :pattern_id, :integer
    add_index :patterns, :pattern_id
  end
end
