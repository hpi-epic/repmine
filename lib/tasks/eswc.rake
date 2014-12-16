require 'csv'

namespace :eswc do
  desc "performs the necessary preparations for a clean experiment structure"
  task :prepare_experiment => [:environment, "db:clear_tmp_folders", "db:teardown_and_rebuild"] do
  end
  
  desc "determines what kind of open task we have here in terms of unmatched concepts"
  task :pre_experiment_statistics => [:environment] do
    
    CSV.open("eswc_2015/stats/pre_manual_matching.csv", "wb") do |csv|
      oaei_ontologies = Ontology.where(:group => "OAEI Conference").order(:short_name)
      csv << Experimenter.csv_header
      oaei_ontologies.each_with_index do |source_ont, i|
        oaei_ontologies[i+1..-1].each do |target_ont|
          expi = Experimenter.new(source_ont, target_ont)
          next unless expi.go_on?
          csv << expi.alignment_info
        end
      end
    end
    puts "*** Matching finshed ***"
  end
  
  desc "uses the created alignments and ontology knowledge to create query graphs, i.e., work items"
  task :create_query_graphs => [:environment] do
    oaei_ontologies.each_with_index do |source_ont, i|
      oaei_ontologies[i+1..-1].each do |target_ont|
        file_path, switch = reference_alignment_for(source_ont, target_ont)
        next if file_path.nil?
        
      end
    end
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
  
  desc "runs the experiment"
  task :run_experiment => [:environment, :prepare_experiment] do
    
  end
end