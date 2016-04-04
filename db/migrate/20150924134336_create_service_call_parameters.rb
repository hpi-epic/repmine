class CreateServiceCallParameters < ActiveRecord::Migration
  def change
    create_table :service_call_parameters do |t|
      t.references :service_call
      t.string :rdf_type
      t.references :service_parameter
      t.timestamps
    end
  end
end
