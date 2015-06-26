class MetricNode < ActiveRecord::Base
  
  attr_accessible :operation, :operator_cd, :operation_cd, :aggregation_id, :pattern_id, :x, :y
  belongs_to :metric
  belongs_to :pattern
  belongs_to :aggregation
  
  as_enum :operation, %i{sum avg min max median}
  as_enum :operator, %i{add subtract multiply divide}
  
  has_ancestry(:orphan_strategy => :rootify)
  
  def is_operator?
    return !operator.nil?
  end
  
  def aggregation_options
    pattern.aggregations.select{|agg| agg.operation != :group_by}
  end
  
  def compute_value(res_hash, aggregated_values = {})
    if is_operator?
      
    else
      
    end
  end
end
