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

require 'rails_helper'

RSpec.describe RdbmsRepository, :type => :model do

  it "should properly run for the test database..." do
    repo = test_repository
    assert_not_nil repo.ontology
    repo.ontology.stub(:local_file_path => testfile)
    errors = repo.extract_ontology!
    puts "Errors during exceution: #{errors || "none"}"
    assert File.exists?(testfile)
    graph = RDF::Graph.load(testfile)
    assert_not_empty graph
  end

  def test_repository
    File.delete(testfile) if File.exists?(testfile)
    config = RepMine::Application.config.database_configuration["development"]
    return RdbmsRepository.create!(
      :db_username => config["username"],
      :db_password => config["password"],
      :db_name => db_type(config) == 3 ? Rails.root.join(config["database"]).to_s : config["database"],
      :host => config["host"],
      :port => config["port"],
      :name => "testdatabase",
      :skip_tables => "schema_migrations,sqlite_sequence",
      :rdbms_type => db_type(config)
    )
  end
  
  def db_type(config)
    return case config["adapter"]
      when "sqlite3" then 3
      when "mysql" then 1
      when "postgres" then 2
      else nil
    end
  end

  def testfile
    Rails.root.join("spec", "testfiles", "testdatabase.ttl").to_s
  end

end
