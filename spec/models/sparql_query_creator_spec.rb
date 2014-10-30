require 'rails_helper'

RSpec.describe SparqlQueryCreator, :type => :model do
  
  before(:each) do
    # we need the patterns, not the repositories
    Pattern.any_instance.stub(:initialize_repository! => true)
  end
  
  it "should create a simple one node query" do
    pattern = FactoryGirl.create(:node_only_pattern)
    qc = SparqlQueryCreator.new(pattern, nil)
    qs = qc.query_string
    assert_not_nil qs
    node_variable = qc.node_variable(pattern.nodes.first)
    assert_equal "SELECT ?#{node_variable} WHERE { ?#{node_variable} a <#{pattern.nodes.first.rdf_type}> . }", qs
  end
  
  it "should create a valid query for a simple node - relation - node pattern" do 
    pattern = FactoryGirl.create(:pattern)
    qc = SparqlQueryCreator.new(pattern, nil)
    qs = qc.query_string
    assert_not_nil qs
  end
  
end