class Metric < ActiveRecord::Base
  attr_accessible :name, :description
  has_many :metric_nodes
  
  def calculate(repository)
    patterns = metric_nodes.where("aggregation_id IS NOT NULL").collect{|mn| mn.aggregation.pattern_element.pattern}.flatten.uniq
    
    results = {}
    # TODO: do not use the pattern, but its translation
    MonitoringTask.where(:pattern_id => patterns.collect{|p| p.id}, :repository_id => repository.id).each do |mt|
      results[mt.pattern] = mt.results
    end
    
    process_results(results)
    return true
  end
  
  def process_results(results)
    join_headers = results.values.collect{|res| res[:headers]}.inject(:&) - leaf_nodes.collect{|ln| ln.aggregation.speaking_name}
    return compute_metrics(combine_results(results, join_headers))
  end
  
  def compute_metrics(complete_results)
    root_nodes = operator_nodes.select{|on| on.is_root?}
    complete_results.each_pair do |res_id, res_object|
      root_nodes.each_with_index do |rn, i| 
        res_object["#{name}_#{i}"] = rn.compute_value(root_node, res_object)
      end
    end
  end
  
  def combine_results(results, join_headers)
    complete_result = {}

    results.each_pair do |pattern, res|
      join_indices = join_headers.collect{|jh| res[:headers].index(jh)}
      copy_them = res[:headers] - join_headers
      copy_ids = copy_them.collect{|cid| res[:headers].index(cid)}      
      
      res[:data].each_with_index do |res_row, i|
        res_row_index = join_indices.collect{|ji| res_row[ji].to_s}.join("_")
        complete_result[res_row_index] ||= {}
        copy_ids.each_with_index{|cid, ii| complete_result[res_row_index]["#{pattern.id}.#{copy_them[ii]}"] = res_row[cid]}
      end
    end
    
    return complete_result
  end
  
  def operator_nodes
    metric_nodes.where("operator_cd IS NOT NULL")
  end
  
  def leaf_nodes
    metric_nodes.where("operator_cd IS NULL")
  end
end
