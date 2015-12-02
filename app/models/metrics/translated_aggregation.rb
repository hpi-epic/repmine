class TranslatedAggregation < Aggregation
  belongs_to :aggregation
  belongs_to :repository

  before_save :set_pattern_element

  def set_pattern_element
    self.pattern_element = matchings.size > 1 ? aggregation_translator.substitute : matchings.first
  end

  def matchings()
    aggregation.pattern_element.matching_elements.where(:ontology_id => repository.ontology.id)
  end

  def aggregation_translator()
    agg_trans = AggregationTranslator.new()
    agg_trans.load_to_engine!(aggregation.pattern_element, matchings)
    return agg_trans
  end

  def operation
    aggregation.operation
  end

  def column_name
    aggregation.column_name
  end

  def alias_name
    aggregation.alias_name
  end

  def distinct
    aggregation.distinct
  end
end