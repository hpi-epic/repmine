class ServiceCall < ActiveRecord::Base
  belongs_to :repository
  belongs_to :service
  belongs_to :pattern, dependent: :destroy

  has_many :service_call_parameters, dependent: :destroy
  accepts_nested_attributes_for :service_call_parameters

  attr_accessor :param_hash

  attr_accessible :service_id, :service_call_parameters_attributes
  after_create :copy_parameters, :create_pattern
  after_save :update_pattern_and_parameters

  def copy_parameters
    service.input_parameters.each{|ip| service_call_parameters.where(service_parameter_id: ip.id, rdf_type: ip.name).first_or_create!}
    service.output_parameters.each{|op| service_call_parameters.where(service_parameter_id: op.id, rdf_type: op.name).first_or_create}
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

  def update_pattern_and_parameters
    input_parameters.each do |ip|
      unless ip.rdf_type.blank?
        ac = pattern.attribute_constraints.where(value: ip.name).first
        ac.update_attributes(rdf_type: ip.rdf_type)
        attrib_domain = repository.ontology.attribute_domain(ip.rdf_type)
        ac.node.update_attributes(rdf_type: attrib_domain.nil? ? ip.rdf_type : attrib_domain.url)
      end
    end

    output_parameters.each do |op|
      unless op.rdf_type.blank? || op.rdf_type.match(URI.regexp(%w(http https)))
        op.update_attributes(rdf_type: repository.ontology.custom_attribute_url(op.rdf_type))
      end
    end
  end

  def aggregations
    Aggregation.where(pattern_element_id: pattern.attribute_constraints.pluck(:id))
  end

  def input_values
    repository.ontology.elements_of_type(RDF::OWL.DatatypeProperty)
  end

  def invoke
    results = repository.results_for_query(attribute_query()).collect do |query_res|
      next if query_res.values.any?{|val| val.blank?}
      service_res = JSON.parse(RestClient.post(service.url, query_res))
      next if service_res.blank?
      [rdf_values(query_res), service_res]
    end.compact

    output_parameters.each{|op| repository.ontology.add_custom_attribute(op.rdf_type, op.datatype, nil)}
    results.each_with_index do |result, i|
      real_result = Hash[result[1].collect{|param_name, value| [output_rdf_type(param_name), value]}]
      query = repository.query_creator_class.new.update_query(result[0], real_result, repository.ontology)
      repository.results_for_query(query)
    end
  end

  def rdf_values(values)
    Hash[values.collect{|param_name, value| [input_rdf_type(param_name), value]}]
  end

  def attribute_query()
    repository.query_creator_class.new(pattern, aggregations).query_string
  end

  def input_rdf_type(name)
    service_call_parameters.find_by_service_parameter_id(service.input_parameters.find_by_name(name)).rdf_type
  end

  def output_rdf_type(name)
    service_call_parameters.find_by_service_parameter_id(service.output_parameters.find_by_name(name)).rdf_type
  end

  def input_parameters
    service_call_parameters.where(service_parameter_id: service.input_parameters.pluck(:id))
  end

  def output_parameters
    service_call_parameters.where(service_parameter_id: service.output_parameters.pluck(:id))
  end
end
