class MonitoringTask < ActiveRecord::Base
  attr_accessible :repository_id, :pattern_id
  
  belongs_to :repository
  belongs_to :pattern
end
