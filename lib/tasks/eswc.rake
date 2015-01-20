require 'csv'

namespace :eswc do
  desc "performs the necessary preparations for a clean experiment structure"
  task :prepare_experiment => [:environment, "db:clear_tmp_folders", "db:teardown_and_rebuild"] do
  end
  
  desc "gets initial stats"
  task :initial_statistics => [:environment, "db:clear_tmp_folders"] do
    puts "** getting initial stats for ontologies and AML results **"
    ontology_packages.each do |ontologies|
      group = ontologies.first.group
      if File.exist?(initial_stat_file(group))
        puts "== Using existing base stat file. Delete #{initial_stat_file(group)} to trigger new run."
      else
        begin
          csv2 = CSV.open(concept_cluster_file(group), "wb")
          csv2 << ["onts", "#C_L", "#CL_L", "#ISO_L", "Concepts_L", "#C_R", "#CL_R", "#ISO_R", "Concepts_R"]
          CSV.open(initial_stat_file(group), "wb") do |csv|
            csv << Experimenter.csv_header
            ontologies.each_with_index do |source_ont, i| 
              ontologies[i+1..-1].each do |target_ont|
                expi = Experimenter.new(source_ont, target_ont)
                if expi.go_on?
                  expi.matcher.match!
                  puts "== Getting stats for #{source_ont.very_short_name}-#{target_ont.very_short_name}"
                  puts "e = Experimenter.new(Ontology.find(#{source_ont.id}), Ontology.find(#{target_ont.id}))"
                  csv << expi.alignment_info
                  rr = [expi.ont_field]
                  expi.reference_properties.each_pair do |ont_very_short, c_stat|
                    rr.concat([
                      c_stat[:classes] + c_stat[:relations] + c_stat[:attributes],
                      c_stat[:isolated].size,
                      c_stat[:cluster_count],
                      c_stat[:isolated].collect{|iso| iso.to_a}.flatten.join(", ")
                    ])
                  end
                  csv2 << rr
                end
              end
            end
          end
          csv2.close
        rescue Exception => e
          csv2.close
          FileUtils.rm(concept_cluster_file(group))          
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
      #Experimenter.experiments.size.times do |i|
        experiment = Experimenter.experiments#[0..i]
        old_csv = CSV.open(initial_stat_file(group), "r").each
        shortest_paths = []
              
        CSV.open(stat_file(group), "a") do |csv|
          csv << [experiment]
          csv << old_csv.next.concat(Experimenter.experiment_header)
          results = []
          ontologies.each_with_index do |source_ont, i|
            ontologies[i+1..-1].each do |target_ont|
              res_row, m1_stats, m2_stats = Experimenter.run_experiment(source_ont, target_ont, experiment)
              unless res_row.nil?
                results << res_row
                csv << old_csv.next.concat(res_row)
                shortest_paths.concat(m1_stats[:min_paths])
                shortest_paths.concat(m2_stats[:min_paths])                
              end
            end
          end
          calc_row = []
          calc_row[16] = results.inject(0){|sum, val| sum += val[4]} / results.size.to_f
          calc_row[21] = results.inject(0){|sum, val| sum += val[9]} / results.size.to_f
          calc_row[26] = results.inject(0){|sum, val| sum += val[14]} / results.size.to_f
          calc_row[31] = results.inject(0){|sum, val| sum += val[19]} / results.size.to_f
          csv << calc_row
          csv << []
        end
        
        File.open("eswc_2015/vault/shortest_paths.yml", "w+"){|f| f.puts shortest_paths.to_yaml}
        puts "And the winners are: #{shortest_paths.inject([]){|x,y| x.concat(y)}.uniq}"
      #end
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
    #[anatomy_ontologies]
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
  
  def concept_cluster_file(group)
    "eswc_2015/vault/eswc_2015_#{group.split(" ").last.downcase}_concept_cluster.csv"
  end
  
  def stat_file(group)
    "eswc_2015/stats/eswc_2015_#{group.split(" ").last.downcase}.csv"
  end
end