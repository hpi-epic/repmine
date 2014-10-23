class CreatePatterns < ActiveRecord::Migration
  def change
    create_table :patterns do |t|
      t.string :name
      t.text :description
      t.text :original_query
      t.integer :query_language_cd
      t.timestamps
    end
  end
end
