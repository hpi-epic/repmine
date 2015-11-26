class Aggregation < ActiveRecord::Base
  attr_accessible :operation, :column_name, :alias_name, :pattern_element_id, :distinct
  as_enum :operation, %i{group_by count sum avg}
  belongs_to :pattern_element
  belongs_to :metric_node

  validate :alias_name, :presence => true, :unless => :is_grouping?

  def speaking_name
    str = operation.to_s + " ("
    str += "#{distinct ? "DISTINCT " : ""}"
    str += "#{column_name.blank? ? pattern_element.speaking_name : column_name})"
    str += " AS #{alias_name}" unless alias_name.blank? # || is_grouping?
    return str
  end

  def translated_to(repository)
    clonty = Aggregation.new(:operation => operation, :column_name => column_name, :alias_name => alias_name)
    matchings = pattern_element.matching_elements.where(:ontology_id => repository.ontology.id)
    clonty.pattern_element = matchings.size > 1 ? aggregation_translator(matchings).substitute : matchings.first
    return clonty
  end

  def aggregation_translator(matchings)
    agg_trans = AggregationTranslator.new()
    agg_trans.load_to_engine!(pattern_element, matchings)
    return agg_trans
  end

  def is_grouping?
    operation == :group_by
  end

  def name_in_result
    if alias_name.blank? # || is_grouping?
      if column_name.blank?
        return pattern_element.speaking_name
      else
        return column_name
      end
    else
      return alias_name
    end
  end

  def underscored_speaking_name
    if is_grouping?
      return name_in_result
    else
      return operation.to_s + "_" + (column_name.blank? ? pattern_element.speaking_name : column_name)
    end
  end

  def compute(array)
    if operation == :avg
      return array.compact.sum / array.compact.size.to_f
    else
      return array.compact.send(operation)
    end
  end
end