class Metric < Measurable
  has_many :metric_nodes
  validates :name, presence: true, uniqueness: true

  def create_node(measurable)
    node = if measurable.is_a?(Pattern)
      MetricNode.create(:measurable_id => measurable.id)
    else
      MetricMetricNode.create(:measurable_id => measurable.id)
    end
    metric_nodes << node
    return node
  end

  # creates the query for each pattern and executes it with the aggregations specified for each metric node
  def run_on_repository(repository)
    results = {}
    threads = []
    metric_nodes.aggregating.each do |metric_node|
      threads << Thread.new{results[metric_node] = metric_node.results_on(repository)}
    end
    threads.each { |thr| thr.join }
    return process_results(results)
  end

  # combines the results by merging overlapping headers and adding the aggregations from both sides
  def process_results(results)
    join_headers = overlapping_result_headers(results) - all_aggregations()
    combined_results = combine_results(results, join_headers)
    return compute_metrics(combined_results)
  end

  # basically finds identical entries in multiple arrays of hashes contained as values in a hash
  def overlapping_result_headers(results)
    results.values.collect{|res| res.collect{|val| val.keys}.flatten.uniq}.inject(:&)
  end

  # calculates metrics for all operator nodes
  def compute_metrics(complete_results)
    root_nodes = operator_nodes.select{|on| on.is_root?}
    return complete_results if root_nodes.empty?

    root_nodes.each do |root_node|
      calculator = Dentaku::Calculator.new
      calculation_template = root_node.calculation_template()
      required_values = root_node.descendants.collect{|ln| ln.qualified_name}.compact
      complete_results.each do |res_object|
        required_values.each{|rv| calculator.store(rv => res_object[rv].to_f)}
        res_object["#{name}"] = begin
          calculator.evaluate(calculation_template).to_f
        rescue Exception => e
          0
        end
      end
    end

    return complete_results
  end

  def combine_results(results, join_headers)
    complete_result = {}

    results.each_pair do |metric_node, values|
      # keys that are not joined need to be made unique
      make_them_unique = values.collect{|val| val.keys}.flatten.uniq - join_headers
      # and should not be overwritten
      do_not_overwrite = make_them_unique.collect{|uh|"#{metric_node.id}_#{uh}"}

      values.each_with_index do |original_res_hash|
        # prevent the method from destroying the original input
        res_hash = original_res_hash.clone
        # replace the keys which would be overwritten
        make_them_unique.each do |uh|
          res_hash["#{metric_node.id}_#{uh}"] = res_hash[uh]
          res_hash.delete(uh)
        end

        # gets a unique ID for each element based on the joined attributes
        res_index = join_headers.collect{|jh| res_hash[jh].to_s}.join("_")
        if complete_result[res_index].nil?
          complete_result[res_index] = [res_hash]
        else
          # if the first thing already has some of our unique keys, we need to be added and merge with them
          if (do_not_overwrite - complete_result[res_index].first.keys).empty?
            complete_result[res_index] << complete_result[res_index].first.merge(res_hash)
          else
            # otherwise, just add all our information to all existing elements
            complete_result[res_index].each{|res| res.merge!(res_hash)}
          end
        end
      end
    end

    return complete_result.values.flatten
  end

  def operator_nodes
    metric_nodes.where(:type => "MetricOperatorNode")
  end

  def leaf_nodes
    metric_nodes.where(:type => [nil, "MetricMetricNode"])
  end

  def executable_on?(repository)
    leaf_nodes.collect{|leaf_node| leaf_node.measurable.executable_on?(repository)}.inject(:&)
  end

  def first_unexecutable_pattern(repository)
    ln = leaf_nodes.find{|leaf_node| !leaf_node.measurable.executable_on?(repository)}
    if ln.nil?
      return nil
    else
      return ln.measurable.first_unexecutable_pattern(repository)
    end
  end

  def result_columns()
    leaf_nodes.collect{|ln| ln.aggregations.collect{|agg| agg.alias_name}}.flatten.uniq + [name]
  end

  def all_aggregations()
    leaf_nodes.aggregating.collect{|ln| ln.aggregation.alias_name}.flatten.compact
  end

  def queries_on(repository)
    leaf_nodes.collect{|leaf_node| leaf_node.query_on(repository)}
  end
end