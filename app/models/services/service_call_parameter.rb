class ServiceCallParameter < ActiveRecord::Base
  belongs_to :service_call
  belongs_to :service_parameter

  attr_accessible :rdf_type, :service_parameter_id
end