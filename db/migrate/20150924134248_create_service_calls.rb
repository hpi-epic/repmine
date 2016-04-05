class CreateServiceCalls < ActiveRecord::Migration
  def change
    create_table :service_calls do |t|
      t.references :service
      t.references :repository
      t.references :pattern
      t.timestamps
    end
  end
end
