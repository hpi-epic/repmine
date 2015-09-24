# TODO: authentication, RAML/Swagger/WSDL parsing
class Service < ActiveRecord::Base
  has_many :service_parameters
  has_many :service_calls
  attr_accessible :name, :description, :url
end