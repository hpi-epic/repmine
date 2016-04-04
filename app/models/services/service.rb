class Service < ActiveRecord::Base
  has_many :input_parameters, :dependent => :destroy
  has_many :output_parameters, :dependent => :destroy
  has_many :service_calls, :dependent => :destroy
  attr_accessible :name, :description, :url
end