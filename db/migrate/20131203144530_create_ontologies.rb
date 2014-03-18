class CreateOntologies < ActiveRecord::Migration
  def change
    create_table :ontologies do |t|
      t.string :url
      t.text :description
      t.string :prefix_url
      t.string :short_name
      t.string :group
      t.timestamps
    end
  end
end
