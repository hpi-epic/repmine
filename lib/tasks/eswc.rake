require 'csv'

namespace :eswc do
  desc "performs the necessary preparations for a clean experiment structure"
  task :prepare_experiment => [:environment, "db:clear_tmp_folders", "db:teardown_and_rebuild"] do
  end
  
  desc "gets initial stats"
  task :initial_statistics => [:environment] do
    puts "** getting initial stats for ontologies and AML results **"
    ontology_packages.each do |ontologies|
      group = ontologies.first.group
      if File.exist?(initial_stat_file(group))
        puts "== Using existing base stat file. Delete #{initial_stat_file(group)} to trigger new run."
      else
        begin
          CSV.open(initial_stat_file(group), "wb") do |csv|    
            csv << Experimenter.csv_header
            ontologies.each_with_index do |source_ont, i| 
              ontologies[i+1..-1].each do |target_ont|
                expi = Experimenter.new(source_ont, target_ont)
                if expi.go_on?
                  expi.matcher.match!
                  puts "== Getting stats for #{source_ont.very_short_name}-#{target_ont.very_short_name}"          
                  csv << expi.alignment_info
                end
              end
            end
          end
        rescue Exception => e
          FileUtils.rm(initial_stat_file(group))
          raise e
        end
      end
    end
  end
  
  desc "uses the created alignments and ontology knowledge to create query graphs, i.e., work items"
  task :run_experiment => [:environment, "eswc:clear_stats", "db:clear_tmp_folders", "eswc:initial_statistics"] do    
    ontology_packages.each do |ontologies|
      group = ontologies.first.group
      Experimenter.experiments.each_with_index do |experiment, i|   
        old_csv = CSV.open(initial_stat_file(group), "r").each
        CSV.open(stat_file(i, group), "w+") do |csv|
          csv << old_csv.next.concat(Experimenter.experiment_header)
          ontologies.each_with_index do |source_ont, i|
            ontologies[i+1..-1].each do |target_ont|
              result = Experimenter.run_experiment(source_ont, target_ont, experiment)
              csv << old_csv.next.concat(result) unless result.nil?
            end
          end
        end
      end
    end
  end
  
  task :clear_stats do
    FileUtils.rm_rf("eswc_2015/stats/.", secure: true)
    FileUtils.rm_rf("eswc_2015/computed_alignments/.", secure: true)
  end
  
  task :clean_reference_alignments => [:environment] do
    Dir.open("eswc_2015/reference_alignments").each do |file|
      fp = "eswc_2015/reference_alignments/" + file
      # skip all non .rdf files
      next if !file.ends_with?(".rdf")
      puts "cleaning #{file}"
      clean_f = File.open(fp).read
      # remove cell ids as they break the raptor rdf-xml parser
      clean_f.gsub!(/ cid='.+?'/, "")
      # and adapt the entity names to the weird ones we get from agraph
      clean_f.scan(/<Ontology rdf:about="(.*?)">/).flatten.each{|ont| clean_f.gsub!("#{ont}#", "#{ont}/#")}
      File.open(fp, "wb"){|f| f.puts clean_f}
    end
  end
  
  def ontology_packages
    [oaei_ontologies]
  end
  
  def oaei_ontologies
    Ontology.where(:group => "OAEI Conference").order(:short_name)
  end
  
  def anatomy_ontologies
    Ontology.where(:group => "OAEI Anatomy").order(:short_name)
  end
  
  def initial_stat_file(group)
    "eswc_2015/vault/eswc_2015_#{group.split(" ").last.downcase}_base.csv"
  end
  
  def stat_file(i, group)
    "eswc_2015/stats/eswc_2015_#{group.split(" ").last.downcase}_#{i}.csv"
  end
end