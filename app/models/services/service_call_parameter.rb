class ServiceCallParameter < ActiveRecord::Base
  belongs_to :service_call
  belongs_to :service_parameter

  attr_accessible :rdf_type, :service_parameter_id
  validates :rdf_type, presence: true, length: {minimum: 2}

  def name
    service_parameter.name
  end

  def datatype
    dt = service_parameter.datatype
    dt.nil? ? RDF::XSD.string : RDF::XSD.send(dt)
  end
end