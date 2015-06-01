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
  as_enum :rdbms_type, mysql: 1, postgresql: 2, sqlite: 3

  validates :rdbms_type, :presence => true
  validates :db_name, :presence => true
  validates :port, numericality: true, allow_blank: true

  def self.model_name
    return Repository.model_name
  end

  def create_ontology!
    cmd = Rails.root.join("externals", "d2rq", "generate-mapping").to_s
    options = ["-v", "-o #{ontology.local_file_path}"]
    options += ["-u #{db_username}"] unless db_username.blank?
    options += ["-p #{db_password}"] unless db_password.blank?
    options += ["-d org.sqlite.JDBC"] if rdbms_type == :sqlite
    options << connection_string
    errors = ""

    Open3.popen3(cmd + " #{options.join(" ")}") do |stdin, stdout, stderr, wait_thr|
      errors = stderr.read
    end
    
    # these errors are mainly warnings telling you that certain fields are ambiguous or so
    # if there are none, just return nil...
    add_ontology_namespace! if File.exists?(ontology.local_file_path)
    return errors
  end
  
  def add_ontology_namespace!
    File.open(ontology.local_file_path + ".new", "w+") do |f2|
      f2.puts("@prefix :\t<#{ontology.url + (ontology.url.end_with?("/") ? "" : "/")}> .")
      File.readlines(ontology.local_file_path).each_with_index do |line, i|
        f2.puts line unless i == 0
      end
    end
    FileUtils.mv(ontology.local_file_path + ".new", ontology.local_file_path)
  end

  def connection_string
    str = if rdbms_type == :sqlite && host.blank?
      "jdbc:#{rdbms_type}://#{db_name.to_s}"
    else
      "jdbc:#{rdbms_type}://#{host}:#{port}/#{db_name}"
    end
    return str
  end

  def type_statistics
    return []
  end
end
