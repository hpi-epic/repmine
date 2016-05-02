# this is a special kind of metric node which does not reference a pattern but another metric
class MetricMetricNode < MetricNode
  attr_accessor :group_headers, :aggregate_headers

  def self.model_name
    return MetricNode.model_name
  end

  def aggregation_options
    measurable.result_columns()
  end

  def results(mt)
    mtn = MonitoringTask.where(:repository_id => mt.repository.id, :measurable_id => measurable.id).first_or_create
    mtn.run unless mtn.has_latest_results?
    return get_aggregates(group_results(mtn.results))
  end

  def translated_aggregations(ontology)
    return aggregations
  end

  def get_aggregates(grouped_results)
    aggregations.non_grouping.each_with_index do |agg|
      grouped_results.each do |res_hash|
        res_hash[agg.alias_name] = agg.compute(res_hash[agg.column_name])
        res_hash.delete(agg.column_name)
      end
    end
    return grouped_results
  end

  def group_results(results)
    grouped_results = {}
    # basically just stores either the value (group criteria) or an array of values
    results.each.with_index do |res_hash, i|
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

  def aggregate_headers()
    @aggregate_headers ||= aggregations.non_grouping.collect{|agg| agg.column_name}
  end

  def group_headers()
    @group_headers ||= aggregations.grouping.collect{|agg| agg.column_name}
  end

  def parameters(mt)
    {}
  end
end