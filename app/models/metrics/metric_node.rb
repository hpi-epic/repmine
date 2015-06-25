class MetricNode < ActiveRecord::Base
  
  attr_accessible :operation, :operator_cd, :operation_cd, :aggregation_id, :x, :y
  belongs_to :metric
  belongs_to :aggregation
  
  as_enum :operation, %i{sum avg min max median}
  as_enum :operator, %i{add subtract multiply divide}
  
  has_ancestry()
  
  def is_operator?
    return !operator.nil?
  end
  
  def aggregation_options
    aggregation.pattern_element.pattern.aggregations.select{|agg| agg.operation != :group_by}
  end
end
