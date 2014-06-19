require 'open3'

class RdbmsRepository < Repository
  
  attr_accessible :rdbms_type, :db_username, :db_password
  as_enum :rdbms_type, mysql: 1, postgresql: 2
  
  def self.model_name
    return Repository.model_name
  end
  
  def extract_ontology!()
    cmd = Rails.root.join("externals", "d2rq", "generate-mapping").to_s
    options = ["-v", "-u #{db_username} -p #{db_password}", "-o #{ont_file_path}", "#{connection_string}"]
    errors = ""
    
    Open3.popen3(cmd + " #{options.join(" ")}") do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
    end
    
    unless errors.empty?
      errors << "\n Errors are in fact warnings. File created successfully!" if File.exist?(ont_file_path)
      raise OntologyExtractionError, errors
    end
  end
  
  def connection_string
    return "jdbc:#{rdbms_type}://#{host}:#{port}/#{db_name}"
  end  
  
  def get_type_stats
    return []
  end
end