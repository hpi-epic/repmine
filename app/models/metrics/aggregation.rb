class Aggregation < ActiveRecord::Base
  attr_accessible :operation, :column_name, :alias_name, :distinct, :pattern_element_id
  as_enum :operation, %i{group_by count sum avg}

  belongs_to :pattern_element
  belongs_to :metric_node
  has_many :translated_aggregations, class_name: "TranslatedAggregation"

  validates :alias_name, presence: true, length: {minimum: 2}, format: { without: /\s/ }

  scope :grouping, where(:operation_cd => Aggregation.operations[:group_by])
  scope :non_grouping, where('operation_cd != ?', Aggregation.operations[:group_by])

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
    str = "#{distinct ? "DISTINCT " : ""}"
    str += "#{column_name.blank? ? pattern_element.name : column_name}"
    str = "#{operation.to_s} (#{str})" unless operation.nil?
    str += " AS #{alias_name}"
    return str
  end

  def translated_to(repo)
    translated_aggregations.where(repository_id: repo.id).first_or_create
  end

  def is_grouping?
    operation == :group_by
  end

  def underscored_speaking_name
    if is_grouping?
      return alias_name
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