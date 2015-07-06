# Delayed Job with progress extension to create an ontology for the repository
class QueryExecutionJob < ProgressJob::Base
  
  attr_accessor :repository_id, :pattern_id, :metric_node_id
  
  # not nice, but works...
  def initialize(*args)
    super()
    @progress_max = args[0][:progress_max] || 100
    @pattern_id = args[0][:pattern_id]
    @metric_node_id = args[0][:metric_node_id]    
    @repository_id = args[0][:repository_id]
  end
  
  def pattern
    @pattern_id.nil? ? MetricNode.find(@metric_node_id).pattern : Pattern.find(@pattern_id)
  end
  
  def perform
    mt = MonitoringTask.where(:repository_id => @repository_id, :pattern_id => @pattern_id, :metric_node_id => @metric_node_id).first
    aggregations = mt.metric_node.nil? ? [] : mt.metric_node.aggregations
    
    query_string = mt.repository.class.query_creator_class.new(mt.the_pattern, aggregations).query_string
    puts "executing query: #{query_string}"
    mt.repository.job = self
    res, csv = mt.repository.execute(query_string)
    
    mt.repository.job = nil
    File.open(mt.results_file("csv"), "w+"){|f| f.puts csv}
    File.open(mt.results_file("yml"), "w+"){|f| f.puts res.to_yaml}
  end
end