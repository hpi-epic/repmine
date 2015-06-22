class CreateMonitoringTasks < ActiveRecord::Migration
  def change
    create_table :monitoring_tasks do |t|
      t.references :pattern
      t.references :repository
      t.timestamps
    end
  end
end
