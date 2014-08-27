class CreateTranslationPatterns < ActiveRecord::Migration
  def change
    create_table :translation_patterns do |t|

      t.timestamps
    end
  end
end
