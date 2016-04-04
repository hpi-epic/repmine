class ServiceCall < ActiveRecord::Base
  belongs_to :repository
  belongs_to :service
  has_many :service_call_parameters

  accepts_nested_attributes_for :service_call_parameters

  attr_accessible :service_id

  def self.for_service_and_repository(service, repo)
    service_call = repo.service_calls.where(service_id: service.id).first_or_create
    service.input_parameters.each{|ip| service_call.service_call_parameters.where(service_parameter_id: ip.id).first_or_create}
    service.output_parameters.each{|op| service_call.service_call_parameters.where(service_parameter_id: op.id).first_or_create}
    return service_call
  end

  def input_values
    repository.ontology.elements_of_type(RDF::OWL.DatatypeProperty)
  end

  def invoke
    # get unique input value combinations
    # invoke service for each of them
    # write the results through the repository
  end
end
