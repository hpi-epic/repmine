class ServiceCallParameter < ActiveRecord::Base
  belongs_to :service_call
  belongs_to :pattern_element
end