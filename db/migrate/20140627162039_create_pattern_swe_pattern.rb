class CreatePatternSwePattern < ActiveRecord::Migration
  def change
    create_table :patterns_swe_patterns, :id => false do |t|
      t.integer :pattern_id
      t.integer :swe_pattern_id
    end
  end
end
