require 'rails_helper'

RSpec.describe RdbmsRepository, :type => :model do

  it "should properly run for the test database..." do
    repo = test_repository
    assert_not_nil repo.ontology
    repo.ontology.stub(:local_file_path => testfile)
    begin
      repo.extract_ontology!
    rescue Repository::OntologyExtractionError => e
      # can happen, but does not really mean anything...
    end
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
      :db_name => config["database"],
      :host => config["host"],
      :port => config["port"],
      :name => "testdatabase",
      :rdbms_type => 2
    )
  end

  def testfile
    Rails.root.join("spec", "testfiles", "testdatabase.ttl").to_s
  end

end
