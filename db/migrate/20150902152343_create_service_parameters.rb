class CreateServiceParameters < ActiveRecord::Migration
  def change
    create_table :service_parameters do |t|
      t.string :name
      t.integer :datatype_cd
      t.references :service
      t.string :type
      t.timestamps
    end
  end
end
