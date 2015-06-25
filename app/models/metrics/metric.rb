class Metric < ActiveRecord::Base
  attr_accessible :name, :description
  
  has_one :root_node, :class_name => "MetricNode"
  has_many :metric_nodes
  
end
