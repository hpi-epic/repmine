namespace :cleanup do
  
  task :hanafy => [:environment] do
    
    ExtractionDescription.all.each do |ed|
      puts "changing extraction description: " + ed.target_ontology_url
      ed.target_ontology_url = ed.target_ontology_url.gsub("-", "")
      ed.save!
    end
    
    Mapping.all.each do |m|
      next if m.element_type.nil?
      m.element_type = m.element_type.gsub("-", "")
      m.save!
    end
    
  end
      
  task :cleanup_demo => [:environment] do 
    graph = Neo4jGraph.new
    graph.graph_db.get_node_index("node_uri_index", "resource_uri", "http://www.hpi-web.de").each do |node|
      graph.graph_db.delete_node!(node)
    end
    graph.graph_db.get_node_index("node_uri_index", "resource_uri", "GoogleGroupsDiscussion").each do |node|
      graph.graph_db.delete_node!(node)
    end
  end
  
  task :entity_names => [:environment] do
    Mapping.all.each do |m|
      m.entity_name = nil
      m.save!
    end
  end
  
end
