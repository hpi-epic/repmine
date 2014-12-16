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
    remove_all_files_from("public/ontologies/tmp", ["owl", "rdf", "n3", "ttl"])
    remove_all_files_from("public/ontologies/extracted", ["owl", "rdf", "n3", "ttl"])    
    remove_all_files_from("public/ontologies/alignments", ["rdf"])    
  end
  
  def remove_all_files_from(folder_name, endings = [])
    Dir.open(folder_name).each do |file|
      regexp = Regexp.compile("\\.(#{endings.join("|")})")
      unless file.match(regexp).nil?
        puts "deleting #{folder_name}/#{file}"
        File.delete(folder_name + "/" + file)
      end
    end
  end
end