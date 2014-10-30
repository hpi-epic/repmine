class CreateSwePatterns < ActiveRecord::Migration
  def change
    create_table :swe_patterns do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
