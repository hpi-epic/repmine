class MetricNode < ActiveRecord::Base
  attr_accessible :aggregation_id, :measurable_id, :x, :y
  belongs_to :metric
  belongs_to :measurable

  # this is the main aggregation we use for further computation
  belongs_to :aggregation

  # these are the ones required to calculate the main one
  has_many :aggregations
  attr_accessor :qualified_name

  validates :aggregation, presence: true, :if => :needs_aggregation?
  scope :aggregating, where("aggregation_id IS NOT NULL")

  has_ancestry(:orphan_strategy => :rootify)

  def calculation_template()
    qualified_name()
  end

  def needs_aggregation?
    !root?
  end

  def qualified_name()
    "#{id}_#{aggregation.alias_name}"
  end

  def results(mt)
    mt.execute_query(query(mt))
  end

  def query(mt)
    mt.query(measurable.translated_to(mt.target_ontology), translated_aggregations(mt.target_ontology))
  end

  def translated_aggregations(ontology)
    return aggregations if ontology.nil? || aggregations.all?{|agg| agg.pattern_element.ontology == ontology}
    aggregations.collect{|agg| agg.translated_to(ontology)}
  end

  def aggregation_options
    measurable.returnable_elements.collect{|pe| [pe.name, pe.id]}
  end
end