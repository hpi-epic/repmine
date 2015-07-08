class CreateMonitoringTasks < ActiveRecord::Migration
  def change
    create_table :monitoring_tasks do |t|
      t.references :repository
      t.references :measurable
      t.timestamps
    end
  end
end
