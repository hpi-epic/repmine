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
      FileUtils.cp(initial_stat_file, stat_file)
    else
      CSV.open(stat_file, "wb") do |csv|    
        csv << Experimenter.csv_header
        oaei_ontologies.each_with_index do |source_ont, i| 
          oaei_ontologies[i+1..-1].each do |target_ont|
            expi = Experimenter.new(source_ont, target_ont)
            if expi.go_on?
              puts "== Getting stats for #{source_ont.very_short_name}-#{target_ont.very_short_name}"          
              csv << expi.alignment_info
              FileUtils.cp(expi.matcher.alignment_path, "eswc_2015/original_alignments/#{expi.matcher.alignment_path.split("/").last}")
            end
          end
        end
      end
      FileUtils.cp(stat_file, initial_stat_file)
    end
  end
  
  desc "uses the created alignments and ontology knowledge to create query graphs, i.e., work items"
  task :run_experiment => [:environment, "eswc:clear_stats", "db:clear_tmp_folders", "eswc:initial_statistics"] do
    old_csv = CSV.open(stat_file, "r").each    
    CSV.open(stat_file_tmp, "w+") do |csv|
      csv << old_csv.next.concat(["#Interactions", "#Additions", "#Removals", "Precision_new", "Recall_New", "F-Measure_new"])
      oaei_ontologies.each_with_index do |source_ont, i|
        oaei_ontologies[i+1..-1].each do |target_ont|
          expi = Experimenter.new(source_ont, target_ont)
          next unless expi.go_on?
          puts "******* Next up: #{source_ont.very_short_name}(#{source_ont.id})-#{target_ont.very_short_name}(#{target_ont.id}) ********"
          interactions = expi.run!
          puts "==== performed matching on #{Pattern.count} patterns ==="
          row = [interactions[:matches] + interactions[:no_idea], interactions[:matches], interactions[:removals]].concat(expi.alignment_stats)
          puts "++++ Stats: #{row} #{interactions} ++++"
          puts "|| Still Missing: ||"
          expi.missing_correspondences.each{|ma| puts ma}
          csv << old_csv.next.concat(row)
          FileUtils.cp(expi.matcher.alignment_path, "eswc_2015/computed_alignments/#{expi.matcher.alignment_path.split("/").last}")                    
        end
      end
    end
    FileUtils.mv(stat_file_tmp, stat_file)    
    puts "** Matching Finished **"
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
  
  def stat_file
    "eswc_2015/stats/eswc_2015.csv"
  end
  
  def initial_stat_file
    "eswc_2015/vault/eswc_2015_base.csv"
  end
  
  def stat_file_tmp
    "eswc_2015/stats/eswc_2015_tmp.csv"
  end  
end