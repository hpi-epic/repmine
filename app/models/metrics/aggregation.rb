class Aggregation < ActiveRecord::Base
  attr_accessible :operation, :column_name, :alias_name, :distinct, :pattern_element_id
  as_enum :operation, %i{group_by count sum avg}
  belongs_to :pattern_element
  belongs_to :metric_node
  has_many :translated_aggregations, class_name: "TranslatedAggregation"

  validate :alias_name, :presence => true, :unless => :is_grouping?

  after_update :update_translations

  def update_translations
    if self.pattern_element_id_changed?
      translated_aggregations.each do |ta|
        ta.set_pattern_element
        ta.save
      end
    end
  end

  def speaking_name
    str = operation.to_s + " ("
    str += "#{distinct ? "DISTINCT " : ""}"
    str += "#{column_name.blank? ? pattern_element.speaking_name : column_name})"
    str += " AS #{alias_name}" unless alias_name.blank?
    return str
  end

  def translated_to(repo)
    translated_aggregations.where(repository_id: repo.id).first_or_create
  end

  def is_grouping?
    operation == :group_by
  end

  def name_in_result
    if alias_name.blank?
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