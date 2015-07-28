class CreatePatternElementMatchings < ActiveRecord::Migration
  def change
    create_table :pattern_element_matches do |t|
      t.integer :matched_element_id
      t.integer :matching_element_id
      t.timestamps
    end
    add_index :pattern_element_matches, :matched_element_id
    add_index :pattern_element_matches, :matching_element_id
  end
end
