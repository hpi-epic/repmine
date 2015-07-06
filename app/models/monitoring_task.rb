class MonitoringTask < ActiveRecord::Base
  attr_accessible :repository_id, :pattern_id, :metric_node_id
  
  belongs_to :repository
  belongs_to :pattern
  belongs_to :metric_node
  
  def self.create_multiple(pattern_ids, repository_id)
    return pattern_ids.collect do |p_id|
      self.where(:pattern_id => p_id, :repository_id => repository_id).first_or_create!.id
    end.uniq
  end
  
  def has_latest_results?
    return File.exist?(results_file("yml")) && File.exist?(results_file("csv"))
  end
  
  def run
    job = QueryExecutionJob.new(:repository_id => repository_id, :pattern_id => pattern_id, :metric_node_id => metric_node_id)
    Delayed::Job.enqueue(job, :queue => repository.query_queue)
  end
  
  def executable?
    translation_unnecessary = (the_pattern.ontologies - [repository.ontology]).empty?
    puts "#{short_name}. translation is unnecessary: #{translation_unnecessary}"
    translation_exists = !TranslationPattern.existing_translation_pattern(the_pattern, [repository.ontology]).nil?
    puts "#{short_name}. translation exists: #{translation_exists}"
    puts "#{short_name}. unmatched_elements: #{the_pattern.unmatched_elements([repository.ontology]).size}"
    return translation_unnecessary || (translation_exists && the_pattern.unmatched_elements([repository.ontology]).empty?)
  end
  
  def the_pattern
    pattern.nil? ? metric_node.pattern : pattern
  end
  
  def short_name
    "#{the_pattern.name} on #{repository.name}"
  end
  
  def results_file(ending)
    return Rails.root.join("public","data","#{filename}.#{ending}").to_s
  end
  
  def filename
    if pattern.nil?
      "metric_node_#{metric_node_id}_repo_#{repository.id}"
    else
      "pattern_#{pattern.id}_repo_#{repository.id}"
    end
  end
  
  def csv_result
    return File.open(results_file("csv")).read
  end
  
  def pretty_csv_name
    return "#{pattern.nil? ? metric_node.metric.name.underscore : pattern.name.underscore}-on-#{repository.name.underscore}.csv"
  end
  
  def results
    return YAML::load(File.open(results_file("yml")).read)
  end
end
