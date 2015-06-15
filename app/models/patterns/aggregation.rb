class Aggregation < ActiveRecord::Base
  attr_accessible :operation
  as_enum :operation, %i{group_by count sum avg}
  belongs_to :pattern_element
end
