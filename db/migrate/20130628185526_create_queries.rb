class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.string :name
      t.text :description
      t.string :repository_name
      t.timestamps
    end
  end
end
