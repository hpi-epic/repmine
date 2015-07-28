class Metric < Measurable
  has_many :metric_nodes

  def create_node(measurable)
    node = if measurable.is_a?(Pattern)
      MetricNode.create(:measurable_id => measurable.id)
    else
      MetricMetricNode.create(:measurable_id => measurable.id)
    end
    metric_nodes << node
    return node
  end

  def run_on_repository(repository)
    results = {}
    metric_nodes.where("aggregation_id IS NOT NULL").each do |metric_node|
      results[metric_node] = metric_node.results_on(repository)
    end
    return process_results(results, repository)
  end

  def process_results(results, repository)
    overlapping_res_headers = results.values.collect{|res| res.collect{|val| val.keys}.flatten.uniq}.inject(:&)
    combined_results = combine_results(results, overlapping_res_headers - all_aggregations(repository))
    complete_results = compute_metrics(combined_results, repository)
    return prepare_results(complete_results, repository)
  end

  def compute_metrics(complete_results, repository)
    root_nodes = operator_nodes.select{|on| on.is_root?}
    return complete_results if root_nodes.empty?

    calculator = Dentaku::Calculator.new
    calculation_template = root_nodes.first.calculation_template(repository)
    required_values = leaf_nodes.collect{|ln| ln.qualified_name(repository)}

    complete_results.each do |res_object|
      required_values.each{|rv| calculator.store(rv => res_object[rv].to_f)}
      res_object["#{name}"] = begin
        calculator.evaluate(calculation_template).to_f
      rescue Exception => e
        0
      end
    end

    return complete_results
  end

  def prepare_results(complete_results, repository)
    headers = complete_results.collect{|val| val.keys}.flatten.uniq
    hf_headers = human_friendly_headers(headers, repository)

    csv_results = CSV.generate do |csv|
      csv << hf_headers
      complete_results.collect do |res_hash|
        res_row = []
        hf_headers.each_with_index do |header,i|
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

  def human_friendly_headers(old_headers, repository)
    hfh = old_headers.clone
    leaf_nodes.each do |ln|
      ln.translated_aggregations(repository).each do |agg|
        index = old_headers.index("#{ln.id}_#{agg.underscored_speaking_name}")
        hfh[index] = agg.name_in_result unless index.nil?
      end
    end
    return hfh
  end

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
    leaf_nodes.collect{|ln| ln.translated_aggregations(repository).collect{|agg| agg.name_in_result}}.flatten.uniq + [name]
  end

  def is_ambiguous?
    aliases = leaf_nodes.collect{|ln| ln.aggregations.collect{|agg| agg.alias_name}}.flatten.compact
    return aliases.uniq.size != aliases.size
  end

  def all_aggregations(repository)
    leaf_nodes.collect{|ln| ln.aggregation_for(repository).underscored_speaking_name}.flatten.compact
  end
end