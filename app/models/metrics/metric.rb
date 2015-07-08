class Metric < Measurable
  
  has_many :metric_nodes
  
  def run_on_repository(repository)
    results = {}
    
    metric_nodes.where("aggregation_id IS NOT NULL").each do |metric_node|
      results[metric_node] = repository.results_for_pattern(metric_node.pattern, metric_node.aggregations, false)
    end
    
    return process_results(results)
  end
  
  def executable_on?(repository)
    leaf_nodes.collect{|leaf_node| leaf_node.pattern.executable_on?(repository)}.inject(:&)
  end
  
  def process_results(results)
    overlapping_res_headers = results.values.collect{|res| res[:headers]}.inject(:&)
    combined_results = combine_results(results, overlapping_res_headers - all_aggregations)
    return compute_metrics(combined_results)
  end
  
  def all_aggregations
    plain_leaf_nodes.collect{|ln| ln.aggregation.speaking_name}
  end
  
  def compute_metrics(complete_results)
    root_nodes = operator_nodes.select{|on| on.is_root?}
    return flatten_results(complete_results) if root_nodes.empty?
    
    calculator = Dentaku::Calculator.new
    aggregated_values(complete_results).each_pair{|av_name, av_value| calculator.store(av_name => av_value.to_f)}
    calculation_template = root_nodes.first.calculation_template
    puts "using template: #{calculation_template}"
    required_values = plain_leaf_nodes.collect{|ln| ln.qualified_name}    
    
    complete_results.each do |res_object|
      required_values.each{|rv| calculator.store(rv => res_object[rv].to_f)}
      res_object["#{name}"] = begin
        calculator.evaluate(calculation_template).to_f
      rescue Exception => e
        0
      end
    end
    
    return flatten_results(complete_results)
  end
  
  def flatten_results(complete_results)
    headers = complete_results.collect{|val| val.keys}.flatten.uniq
    puts "headers: #{headers}"
    
    data = []
    csv_results = CSV.generate do |csv|
      csv << headers
      data = complete_results.collect do |k| 
        res_row = []
        k.each_pair{|kk,vv| res_row[headers.index(kk)] = vv}
        csv << res_row
        res_row
      end
    end
    
    return {:headers => headers, :data => data}, csv_results
  end
  
  def aggregated_values(complete_results)
    aggregation_values = {}
    aggregation_leaf_nodes.each do |aln|
      puts "getting #{aln.operation} of all #{aln.qualified_name}"
      aggregation_values[aln.fully_qualified_name] = aln.compute(complete_results.collect{|k,v| v[aln.qualified_name]})
    end
    puts "complete aggregations: #{aggregation_values}"
    return aggregation_values
  end
  
  def combine_results(results, join_headers)
    complete_result = {}
    order = results.keys.sort_by{|key| results[key][:headers].size}.reverse.collect{|key| results.keys.index(key)}

    order.each_with_index do |key_index, i|
      metric_node = results.keys[key_index]
      res = results[metric_node]
      
      join_indices = join_headers.collect{|jh| res[:headers].index(jh)}
      copy_them = res[:headers] - join_headers
      copy_indices = copy_them.collect{|cid| res[:headers].index(cid)}
      
      res[:data].each do |res_row|
        res_hash = {}
        copy_indices.each_with_index{|cid, ii| res_hash["#{metric_node.id}_#{copy_them[ii]}"] = res_row[cid]}
        join_indices.each_with_index{|cid, ii| res_hash[res[:headers][cid]] = res_row[cid]}
        res_row_index = join_indices.collect{|ji| res_row[ji].to_s}.join("_")
        complete_result[res_row_index] ||= []
        if i == 0
          complete_result[res_row_index] << res_hash
        else
          complete_result[res_row_index].each do |rr|
            rr.merge!(res_hash)
          end
        end
      end
    end
    
    return complete_result.values.flatten
  end
  
  def operator_nodes
    metric_nodes.where("operator_cd IS NOT NULL")
  end
  
  def leaf_nodes
    metric_nodes.where("operator_cd IS NULL")
  end
  
  def plain_leaf_nodes
    metric_nodes.where("operator_cd IS NULL AND operation_cd IS NULL")
  end
  
  def aggregation_leaf_nodes
    metric_nodes.where("operator_cd IS NULL AND operation_cd IS NOT NULL")
  end
end