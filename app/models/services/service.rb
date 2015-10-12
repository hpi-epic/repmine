# TODO: authentication, RAML/Swagger/WSDL parsing
class Service < ActiveRecord::Base
  has_many :service_parameters, :dependent => :destroy
  has_many :service_calls, :dependent => :destroy
  attr_accessible :name, :description, :url
end