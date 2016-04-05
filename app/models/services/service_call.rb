class ServiceCall < ActiveRecord::Base
  belongs_to :repository
  belongs_to :service
  belongs_to :pattern

  has_many :service_call_parameters, dependent: :destroy
  accepts_nested_attributes_for :service_call_parameters

  attr_accessible :service_id, :service_call_parameters_attributes
  after_create :copy_parameters, :create_pattern
  after_save :update_pattern

  def copy_parameters
    service.input_parameters.each{|ip| service_call_parameters.where(service_parameter_id: ip.id).first_or_create}
    service.output_parameters.each{|op| service_call_parameters.where(service_parameter_id: op.id).first_or_create}
  end

  def create_pattern
    self.pattern = Pattern.create(name: "Service Call #{id}", description: "blank", ontologies: [repository.ontology])
    input_parameters.each do |input_parameter|
      ac = AttributeConstraint.create!(
        value: input_parameter.name,
        operator: AttributeConstraint::OPERATORS[:var],
        node: self.pattern.create_node!(repository.ontology)
      )
      Aggregation.create(pattern_element_id: ac.id, distinct: true, alias_name: input_parameter.name)
    end
    self.save
  end

  def update_pattern
    input_parameters.each do |input_parameter|
      ac = pattern.attribute_constraints.where(value: input_parameter.name).first
      ac.rdf_type = input_parameter.rdf_type
      ac.node.rdf_type = repository.ontology.attribute_domain(input_parameter.rdf_type)
    end
  end

  def aggregations
    Aggregation.where(pattern_element_id: pattern.attribute_constraints.pluck(:id))
  end

  def input_values
    repository.ontology.elements_of_type(RDF::OWL.DatatypeProperty)
  end

  def invoke
    results = repository.results_for_query(attribute_query()).collect do |values|
      next if values.values.any?{|val| val.blank?}
      {values => JSON.parse(RestClient.post(service.url, values))}
    end.compact

    results.each_pair do |parameters, result|
      real_params = {}
      parameters.each_pair{|param_name, value| real_params[input_parameter(param_name)] = value}
      repository.query_creator_class.new.insert_query(real_params, result)
    end
  end

  def attribute_query()
    repository.query_creator_class.new(pattern, aggregations).query_string
  end

  def input_parameter(name)
    input_parameters.find{|ip| ip.name == name}
  end

  def input_parameters
    service_call_parameters.where(service_parameter_id: service.input_parameters.pluck(:id))
  end

  def output_parameters
    service_call_parameters.where(service_parameter_id: service.output_parameters.pluck(:id))
  end
end
