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

  def results_on(repository)
    repository.results_for_pattern(measurable.translated_to(repository), translated_aggregations(repository))
  end

  def query_on(repository)
    repository.query_for_pattern(measurable.translated_to(repository), translated_aggregations(repository))
  end

  def translated_aggregations(repository)
    return aggregations if repository.nil? || aggregations.all?{|agg| agg.pattern_element.ontology == repository.ontology}
    aggregations.collect{|agg| agg.translated_to(repository)}
  end

  def aggregation_options
    measurable.returnable_elements([]).collect{|pe| [pe.speaking_name, pe.id]}
  end
end