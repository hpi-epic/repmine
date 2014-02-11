class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
