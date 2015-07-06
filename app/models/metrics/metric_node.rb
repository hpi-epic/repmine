class MetricNode < ActiveRecord::Base
  
  attr_accessible :operation, :operator_cd, :operation_cd, :aggregation_id, :pattern_id, :x, :y
  belongs_to :metric
  belongs_to :pattern
  belongs_to :aggregation  
  has_many :aggregations
  attr_accessor :qualified_name
  
  as_enum :operation, %i{sum avg min max}
  as_enum :operator, %i{add subtract multiply divide}
  OPERATOR_MAPPING = {:add => "+", :subtract => "-", :multiply => "*", :divide => "/"}  
  
  has_ancestry(:orphan_strategy => :rootify)
  
  def operator?
    return !operator.nil?
  end
  
  def calculation_template
    if operator?
      return "(#{children.collect{|child| child.calculation_template}.join(math_op)})"
    else
      return fully_qualified_name
    end
  end
  
  def qualified_name
    @qualified_name ||= "#{id}_#{aggregation.speaking_name}"
  end
  
  def fully_qualified_name
    "#{operation}#{operation.nil? ? "" : "_"}#{qualified_name}"
  end
  
  def compute(array)
    if operation == :avg 
      return array.compact.sum / array.compact.size.to_f
    else
      return array.compact.send(operation)
    end
  end
  
  def math_op()
    return OPERATOR_MAPPING[operator]
  end
end
