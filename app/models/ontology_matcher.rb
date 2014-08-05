require 'open3'

class OntologyMatcher
  
  attr_accessor :ag_connection, :source_ont, :target_ont
  
  def initialize(pattern, ont_s, ont_t)
    @pattern = pattern
    @source_ont = ont_s
    @target_ont = ont_t
  end
  
  def match!()
    [source_ont, target_ont].each{|ont| ont.download!}
    cmd = "java -jar aml.jar -m -s #{source_ont.local_path} -t #{target_ont.local_path} -o #{alignment_path}"
    puts cmd
    Open3.popen3(cmd, :chdir => Rails.root.join("externals", "aml")) do |stdin, stdout, stderr, wait_thr|
      puts "+++ err: " + stderr.read
      puts "+++ info: " + stdout.read
    end
    # TODO:
    # put the result to the triple store
  end
  
  # this is where the magic will happen
  def get_substitute_for(element)
    
  end
  
  def alignment_path
    Rails.root.join("public", "ontologies", "alignments",  "#{source_ont.short_name}_#{target_ont.short_name}.rdf")
  end
  
end