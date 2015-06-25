class Aggregation < ActiveRecord::Base
  attr_accessible :operation
  as_enum :operation, %i{group_by count sum avg}
  belongs_to :pattern_element
  
  def speaking_name
    return pattern_element.speaking_name + "_" + operation.to_s
  end
end
