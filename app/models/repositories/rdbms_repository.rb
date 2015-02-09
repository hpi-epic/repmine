# == Schema Information
#
# Table name: repositories
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  db_name       :string(255)
#  db_username   :string(255)
#  db_password   :string(255)
#  host          :string(255)
#  port          :integer
#  description   :text
#  ontology_id   :integer
#  type          :string(255)
#  rdbms_type_cd :integer
#

require 'open3'

class RdbmsRepository < Repository

  attr_accessible :rdbms_type
  as_enum :rdbms_type, mysql: 1, postgresql: 2

  validates :rdbms_type, :presence => true
  validates :db_name, :presence => true
  validates :host, :presence => true
  validates :port, :presence => true

  def self.model_name
    return Repository.model_name
  end

  def create_ontology!
    cmd = Rails.root.join("externals", "d2rq", "generate-mapping").to_s
    options = ["-v", "-u #{db_username} -p #{db_password}", "-o #{ontology.local_file_path}", "#{connection_string}"]
    errors = ""

    Open3.popen3(cmd + " #{options.join(" ")}") do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
    end
    
    return File.exist?(ontology.local_file_path)
  end

  def connection_string
    return "jdbc:#{rdbms_type}://#{host}:#{port}/#{db_name}"
  end

  def type_statistics
    return []
  end
end
