class Aggregation < ActiveRecord::Base
  attr_accessible :operation
  as_enum :operation, %i{group_by count sum avg}
  belongs_to :pattern_element
  belongs_to :metric_node
  
  def speaking_name
    return pattern_element.speaking_name + "_" + operation.to_s
  end
end
