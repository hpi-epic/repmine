class Metric < Measurable
  has_many :metric_nodes
  validates :name, presence: true

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
    metric_nodes.where("aggregation_id IS NOT NULL").each do |metric_node|
      threads << Thread.new{results[metric_node] = metric_node.results_on(repository)}
    end
    threads.each { |thr| thr.join }
    return process_results(results, repository)
  end

  # combines the results by merging overlapping headers and adding the aggregations from both sides
  def process_results(results, repository)
    combined_results = combine_results(results, overlapping_result_headers(results) - all_aggregations(repository))
    complete_results = compute_metrics(combined_results, repository)
    return prepare_results(complete_results, repository)
  end

  # basically finds identical entries in multiple arrays of hashes contained as values in a hash
  def overlapping_result_headers(results)
    results.values.collect{|res| res.collect{|val| val.keys}.flatten.uniq}.inject(:&)
  end

  # calculates metrics for all operator nodes
  def compute_metrics(complete_results, repository)
    root_nodes = operator_nodes.select{|on| on.is_root?}
    return complete_results if root_nodes.empty?

    root_nodes.each do |root_node|
      calculator = Dentaku::Calculator.new
      calculation_template = root_node.calculation_template(repository)
      required_values = leaf_nodes.collect{|ln| ln.qualified_name}
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

  def prepare_results(complete_results, repository)
    headers = complete_results.collect{|val| val.keys}.flatten.uniq

    csv_results = CSV.generate do |csv|
      csv << headers
      complete_results.collect do |res_hash|
        res_row = []
        headers.each_with_index do |header,i|
          if !res_hash.has_key?(header)
            res_hash[header] = res_hash[headers[i]]
            res_hash.delete(headers[i])
          end
          res_row << res_hash[header]
        end
        csv << res_row
      end
    end

    return complete_results, csv_results
  end

  #
  def combine_results(results, join_headers)
    complete_result = {}
    results.each_pair do |metric_node, values|
      make_them_unique = values.collect{|val| val.keys}.flatten.uniq - join_headers
      do_not_overwrite = make_them_unique.collect{|uh|"#{metric_node.id}_#{uh}"}

      values.each_with_index do |res_hash|
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

  def translate_column(column_name, repository)
    result_columns(repository)[result_columns.index(column_name)]
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

  def result_columns(repository = nil)
    leaf_nodes.collect{|ln| ln.aggregations.collect{|agg| agg.alias_name}}.flatten.uniq + [name]
  end

  def all_aggregations(repository)
    leaf_nodes.collect{|ln| ln.aggregation.alias_name}.flatten.compact
  end
end