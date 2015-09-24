class CreateServiceCallParameters < ActiveRecord::Migration
  def change
    create_table :service_call_parameters do |t|
      t.references :service_call
      t.references :pattern_element
      t.timestamps
    end
  end
end
