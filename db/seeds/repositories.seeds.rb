#puts "creating Rails repository"
#MongoDbRepository.find_or_create_by_host_and_db_name("172.16.31.74", "msr14", :port => 27017, :name => "GHTorrent", :description => "GHTorrent dataset for the 2014 working conference on mining software repositories")
#rails = MongoDbRepository.find_or_create_by_host_and_db_name("172.16.31.74", "rails", :port => 27017, :name => "Rails", :description => "Dataset for the Rails project including Stackoverflow questions")
#if File.exist?(rails.ontology.local_file_path)
#  rails.ontology.update_attributes({:does_exist => true})
#end
