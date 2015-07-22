# this is a special kind of metric node which does not reference a pattern but another metric 
class MetricMetricNode < MetricNode
  attr_accessor :group_headers, :aggregate_headers

  def self.model_name
    return MetricNode.model_name
  end

  def aggregation_options
    measurable.result_columns()
  end
  
  def results_on(repository)
    mt = MonitoringTask.where(:repository_id => repository.id, :measurable_id => measurable.id).first_or_create
    mt.run unless mt.has_latest_results?
    translate_column_names!(repository)
    return get_aggregates(group_results(mt.results))
  end
  
  def translate_column_names!(repository)
    aggregate_headers(repository)
    group_headers(repository)
  end
  
  def translated_aggregations(repository)
    return aggregations
  end
  
  def get_aggregates(grouped_results)
    non_grouping_aggregations.each_with_index do |agg, i|
      grouped_results.each do |res_hash|
        res_hash[agg.name_in_result] = agg.compute(res_hash[aggregate_headers[i]])
      end
    end
    aggregate_headers.each{|header| grouped_results.each{|res| res.delete(header)}}
    return grouped_results
  end
  
  def group_results(results)
    grouped_results = {}
    
    results.each do |res_hash|
      g_hash = group_headers.collect{|gh| res_hash[gh].to_s}.join("_")
      if grouped_results[g_hash].nil?
        grouped_results[g_hash] = {}
        aggregate_headers.each{|h| grouped_results[g_hash][h] = [res_hash[h]]}
        group_headers.each{|h| grouped_results[g_hash][h] = res_hash[h]}    
      else
        aggregate_headers.each{|h| grouped_results[g_hash][h] += [res_hash[h]]}
      end
    end
    
    return grouped_results.values
  end
  
  def non_grouping_aggregations
    aggregations.where('operation_cd != ?', 0)
  end
  
  def aggregate_headers(repository = nil)
    @aggregate_headers ||= non_grouping_aggregations.collect{|agg| measurable.translate_column(agg.column_name, repository)}
  end
  
  def group_headers(repository = nil)
    @group_headers ||= aggregations.where(:operation_cd => 0).collect{|agg| measurable.translate_column(agg.name_in_result, repository)}
  end
end