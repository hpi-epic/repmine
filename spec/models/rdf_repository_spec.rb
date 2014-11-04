require 'rails_helper'
require_relative '../testfiles/test_ontology'

RSpec.describe Repository, :type => :model do
  
  before(:each) do
    @agc = AgraphConnection.new("__XX__TEST__")
  end
  
  it "should return correct type statistics" do    
    prepare_repository!({TestOntology.ClassA => 0, TestOntology.ClassB => 5, TestOntology.ClassC => 5000, TestOntology.ClassD => 15})
    @repo = repository_from_connection(@agc)
    type_stats = @repo.type_statistics
    assert_not_empty type_stats
    assert_equal 5, type_stats.find{|ts| ts[0] == TestOntology.ClassB}[1]
    assert_equal 5000, type_stats.find{|ts| ts[0] == TestOntology.ClassC}[1]
    assert_equal 15, type_stats.find{|ts| ts[0] == TestOntology.ClassD}[1]        
    assert_nil type_stats.find{|ts| ts[0] == TestOntology.ClassA}
  end
  
  it "should create a proper ontology instance for the repository" do
    prepare_repository!
    @repo = repository_from_connection(@agc)
    assert @repo.ontology.is_a?(Ontology)
    assert !@repo.ontology.is_a?(ExtractedOntology)
    assert_equal TestOntology.to_s, @repo.ontology.url
  end
  
  def repository_from_connection(agc)
    return FactoryGirl.create(:rdf_repository,
      :db_name => "repositories/" + agc.repository_name + "#query", 
      :host => agc.config["host"], 
      :port => agc.config["port"],
      :db_username => agc.config["username"],
      :db_password => agc.config["password"]
    )
  end
  
  def prepare_repository!(test_distribution = {})
    @agc.clear!    
    stmts = []
    TestOntology.each_statement{|stmt| stmts << stmt}
    test_distribution.each_pair do |ttype, count|
      count.times do |i|
        stmts << [RDF::Node.new, RDF.type, ttype]
      end 
    end
    @agc.repository.insert(*stmts)
  end
  
end