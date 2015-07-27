class MetricNode < ActiveRecord::Base  
  attr_accessible :aggregation_id, :measurable_id, :x, :y
  belongs_to :metric
  belongs_to :measurable
  
  # this is the main aggregation we use for further computation
  belongs_to :aggregation
  
  # these are the ones required to calculate the main one
  has_many :aggregations
  attr_accessor :qualified_name
  
  has_ancestry(:orphan_strategy => :rootify)
  
  def calculation_template(repository)
    qualified_name(repository)
  end
  
  def results_on(repository)
    repository.results_for_pattern(measurable_for(repository), translated_aggregations(repository), false)
  end
  
  def translated_aggregations(repository)
    return aggregations if repository.nil? || aggregations.all?{|agg| agg.pattern_element.ontology == repository.ontology}
    aggregations.collect{|agg| agg.clone_for(repository)}
  end
  
  def aggregation_for(repository)
    return aggregation if repository.nil? || aggregation.pattern_element.ontology == repository.ontology
    aggregation.clone_for(repository)
  end
  
  def measurable_for(repository)
    if measurable.translation_unnecessary?(repository)
      return measurable
    else
      return TranslationPattern.existing_translation_pattern(measurable, [repository.ontology])
    end
  end
  
  def aggregation_options
    measurable.returnable_elements([]).collect{|pe| [pe.speaking_name, pe.id]}
  end
  
  def qualified_name(repository)
    @qualified_name ||= "#{id}_#{aggregation_for(repository).underscored_speaking_name}"
  end
end