namespace :import do
  
  task :create_samples => [:environment] do
    Dir.open(Rails.root.join("data").to_s).each do |file|
      if file.ends_with?(".json")
        j = MultiJson.load(File.open(Rails.root.join("data", file).to_s).read)
        File.open(Rails.root.join("data", "samples", file).to_s, "w+"){|f| f.puts j.first.to_json}
      end
    end
  end
  
  task :profile => [:environment] do
    
    graph = Graph.new_for_type(ENV["GRAPH_TYPE"])
    limit = ENV["LIMIT"] || 1000
    
    data = {:file => "rails_rails_commit_details.json", :ontology_url => "http://hpiweb.de/ontologies/collaboration/github/commits/"}
    #data = {:file => "stackoverflow.json", :ontology_url => "http://hpiweb.de/ontologies/collaboration/stackoverflow/"}
    
    ed = ExtractionDescription.where(:target_ontology_url => data[:ontology_url]).first
    raise "no exctration description found" if ed.nil?    
    json = MultiJson.load(File.open("data/" + data[:file]).read)
    
    require 'ruby-prof'

    RubyProf.start
    graph.import_json!(json[0..limit], ed)
    result = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(File.open("profile_initial.html", "w+"))
    
    puts "round 2"
    RubyProf.start
    graph.import_json!(json[0..limit], ed)
    result = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(File.open("profile_with_lookup.html", "w+"))
  end
  
  task :entire_project => [:environment] do
    todos = [
      {:file => "rails_rails_commit_details.json", :ontology_url => "http://hpiweb.de/ontologies/collaboration/github/commits/"},      
      {:file => "stackoverflow.json", :ontology_url => "http://hpiweb.de/ontologies/collaboration/stackoverflow/"},      
      {:file => "rails_rails_ticket_events.json", :ontology_url => "http://hpiweb.de/ontologies/collaboration/github/issue_tracking/events/"},
      {:file => "rails_rails_ticket_comments.json", :ontology_url => "http://hpiweb.de/ontologies/collaboration/github/issue_tracking/comments/"}
    ]
    
    start_of_coffee_break = Time.now
    
    graph = Graph.new_for_type(ENV["GRAPH_TYPE"])
    
    todos.each do |todo|
      json = MultiJson.load(File.open(Rails.root.join("data", todo[:file]).to_s).read)      
      ed = ExtractionDescription.where(:target_ontology_url => todo[:ontology_url]).first      
      raise "no extraction_description found for #{todo[:ontology_url]}" if ed.nil?      
      
      # let's do that until the mappings are final...
      mapping_incomplete = true
      while mapping_incomplete
        puts "parsing json from #{todo[:file]}"
        begin
          x = Time.now            
          graph.import_json!(json, ed)
          puts "done importing #{todo[:file]}. took: #{Time.now - x} seconds"          
          mapping_incomplete = false
        rescue Graph::MappingChangedException => e
          puts "The mappings have changed! Please fix them using the editor and press enter, once you're done..."
          STDIN.gets
          puts "starting again!"
        end
      end
    end
    puts "done importing. took: #{Time.now - start_of_coffee_break} seconds"    
  end
    
  task :clear => [:environment] do
    graph = Graph.new_for_type(ENV["GRAPH_TYPE"])
    graph.clear!  
    graph.create_tbox!()
  end
  
  task :prepare => [:environment] do
    graph = Graph.new_for_type(ENV["GRAPH_TYPE"])
    graph.create_tbox!()
  end 
end