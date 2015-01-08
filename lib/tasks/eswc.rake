require 'csv'

namespace :eswc do
  desc "performs the necessary preparations for a clean experiment structure"
  task :prepare_experiment => [:environment, "db:clear_tmp_folders", "db:teardown_and_rebuild"] do
  end
  
  desc "gets initial stats"
  task :initial_statistics => [:environment] do
    puts "** getting initial stats for ontologies and AML results **"
    if File.exist?(initial_stat_file)
      puts "== Using existing base stat file. Delete #{initial_stat_file} to trigger new run."
    else
      CSV.open(initial_stat_file, "wb") do |csv|    
        csv << Experimenter.csv_header
        oaei_ontologies.each_with_index do |source_ont, i| 
          oaei_ontologies[i+1..-1].each do |target_ont|
            expi = Experimenter.new(source_ont, target_ont)
            if expi.go_on?
              expi.matcher.match!
              puts "== Getting stats for #{source_ont.very_short_name}-#{target_ont.very_short_name}"          
              csv << expi.alignment_info
            end
          end
        end
      end
    end
  end
  
  desc "uses the created alignments and ontology knowledge to create query graphs, i.e., work items"
  task :run_experiment => [:environment, "eswc:clear_stats", "db:clear_tmp_folders", "eswc:initial_statistics"] do    
    #Experimenter.experiments.each_with_index do |experiment, i|
    [nil].each_with_index do |experiment, i|      
      old_csv = CSV.open(initial_stat_file, "r").each
      CSV.open(stat_file(i), "w+") do |csv|
        csv << old_csv.next.concat(Experimenter.experiment_header)
        oaei_ontologies.each_with_index do |source_ont, i|
          oaei_ontologies[i+1..-1].each do |target_ont|
            result = Experimenter.run_experiment(source_ont, target_ont, experiment)
            csv << old_csv.next.concat(result) unless result.nil?
          end
        end
      end
    end
  end
  
  def experiment_prefix(experiment)
    experiment.collect{|x| x.to_s.split("_").collect{|xy| xy.first}.join}.join.upcase
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
      clean_f = File.open(fp).read
      # remove cell ids as they break the raptor rdf-xml parser
      clean_f.gsub!(/ cid='.+?'/, "")
      # and adapt the entity names to the weird ones we get from agraph
      clean_f.scan(/<Ontology rdf:about="(.*?)">/).flatten.each{|ont| clean_f.gsub!("#{ont}#", "#{ont}/#")}
      File.open(fp, "wb"){|f| f.puts clean_f}
    end
  end
  
  def oaei_ontologies
    Ontology.where(:group => "OAEI Conference").order(:short_name)
  end
  
  def initial_stat_file
    "eswc_2015/vault/eswc_2015_base.csv"
  end
  
  def stat_file(i)
    "eswc_2015/stats/eswc_2015_#{i}.csv"
  end
end