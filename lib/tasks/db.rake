namespace :db do
  desc "Rebuilds the entire application without leaving any allegrograph repositories on base"
  task :teardown_and_rebuild => [:environment] do
    puts "====== Clearing Allegrograph Repositories ======== "
    Ontology.all.each{|o| 
      puts "Deleting: #{o.repository_name}"
      o.delete_repository!
    }
    puts "Done. Continuing with standard db creation..."
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed:ontologies"].invoke            
  end
  
  desc "Builds a fresh application"
  task :build_fresh => ["db:drop", "db:create", "db:migrate", "db:seed"]
  
  desc "clear all downloaded ontologies, created alignments, etc"
  task :clear_tmp_folders do
    remove_all_files_from("public/ontologies/tmp")
    remove_all_files_from("public/ontologies/extracted")    
    remove_all_files_from("public/ontologies/alignments")    
  end
  
  def remove_all_files_from(folder_name)
    puts "= clearing #{folder_name} ="
    FileUtils.rm_rf("#{folder_name}/.", secure: true)
  end
end