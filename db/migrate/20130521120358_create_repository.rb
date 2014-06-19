class CreateRepository < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :db_name
      t.string :db_username
      t.string :db_password
      t.string :host
      t.integer :port
      t.text :description
      t.string :type
    end
  end
end
