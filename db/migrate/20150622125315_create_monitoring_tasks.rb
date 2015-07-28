class CreateMonitoringTasks < ActiveRecord::Migration
  def change
    create_table :monitoring_tasks do |t|
      t.references :repository
      t.references :measurable
      t.timestamps
    end
    
    add_index :monitoring_tasks, :repository_id    
    add_index :monitoring_tasks, :measurable_id        
  end
end
