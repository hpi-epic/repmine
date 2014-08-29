class CreateOntologies < ActiveRecord::Migration
  def change
    create_table :ontologies do |t|
      t.string :url
      t.text :description
      t.string :short_name
      t.string :group
      t.boolean :does_exist, :default => true
      t.timestamps
    end
  end
end
