namespace :db do
  desc "Rebuilds the entire application without leaving any allegrograph repositories on base"
  task :teardown_and_rebuild => [:environment] do
    puts "====== Clearing Allegrograph Repositories ======== "
    clear_ontologies()
    puts "Done. Continuing with standard db creation..."
    Rake::Task["db:clear_tmp_folders"].invoke
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
  end

  desc "Builds a fresh application"
  task :build_fresh => ["db:drop", "db:create", "db:migrate", "db:seed"]

  desc "clear all downloaded ontologies, created alignments, etc"
  task :clear_tmp_folders do
    puts "== clearing all tmp folders =="
    remove_all_files_from("public/ontologies/tmp")
    remove_all_files_from("public/ontologies/extracted")
    remove_all_files_from("public/ontologies/alignments")
    remove_all_files_from("public/data")
  end

  def clear_ontologies(remove = true)
    ontologies = Ontology.all
    ontologies.each_with_index do |o, i|
      if remove
        puts "Deleting: #{o.repository_name}"
        o.delete_repository!
      end

      ontologies[i+1..-1].each do |to|
        om = OntologyMatcher.new(o, to)
        om.delete_alignment_repository!
        puts "Deleting Alignment repository: #{om.repo_name}"
      end
    end
  end

  def remove_all_files_from(folder_name)
    puts "= clearing #{folder_name} ="
    FileUtils.rm_rf(Dir.glob("#{folder_name}/*"))
  end

  desc "removes everything that is created throughout the demo, but leaves the necessary stuff intact"
  task demo_reset: [:environment] do
    TranslationPattern.destroy_all
    Correspondence.destroy_all
    clear_ontologies(false)
    Repository.all.each{|repo| repo.ontology.update_attributes(:does_exist => false) if repo.ontology.is_a?(ExtractedOntology)}
    MonitoringTask.destroy_all
    Metric.destroy_all
  end
end