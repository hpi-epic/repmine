class CreateServiceParameters < ActiveRecord::Migration
  def change
    create_table :service_parameters do |t|
      t.string :name
      t.integer :datatype_cd
      t.boolean :is_collection, :default => true
      t.references :service
      t.timestamps
    end
  end
end
