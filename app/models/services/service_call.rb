class ServiceCall < ActiveRecord::Base
  belongs_to :pattern
  belongs_to :service
  has_many :service_call_parameters

  def run()

  end
end
