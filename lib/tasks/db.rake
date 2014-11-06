namespace :db do
  desc "Rebuilds the entire application without leaving any allegrograph repositories on base"
  task :teardown_and_rebuild => [:environment] do
    puts "====== Clearing Allegrograph Repositories ======== "
    Ontology.all.each{|o| 
      puts "Deleting: #{o.repository_name}"
      o.delete_repository!
    }
    Pattern.all.each{|p| 
      puts "Deleting: #{p.repository_name}"
      p.delete_repository!
    }
    puts "Done. Continuing with standard db creation..."
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke            
  end
  
  desc "Builds a fresh application"
  task :build_fresh => ["db:drop", "db:create", "db:migrate", "db:seed"]
end