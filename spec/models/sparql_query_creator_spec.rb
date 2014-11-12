require 'rails_helper'

RSpec.describe SparqlQueryCreator, :type => :model do
  
  it "should create a simple one node query" do
    pattern = FactoryGirl.create(:node_only_pattern)
    qc = SparqlQueryCreator.new(pattern, nil)
    qs = qc.query_string
    assert_not_nil qs
    pe_variable = qc.pe_variable(pattern.nodes.first)
    assert_equal "SELECT ?#{pe_variable} WHERE { ?#{pe_variable} a <#{pattern.nodes.first.rdf_type}> . }", qs
  end
  
  it "should create a valid query for a simple node - self-relation - node pattern" do 
    pattern = FactoryGirl.create(:pattern)
    qc = SparqlQueryCreator.new(pattern, nil)
    qs = qc.query_string
    nv = qc.pe_variable(pattern.nodes.first)
    assert_equal qs, "SELECT ?#{nv} WHERE { ?#{nv} a <http://example.org/node> . ?#{nv} http://example.org/relation ?#{nv} . ?#{nv} http://example.org/attribute \"hello world\" . }"
  end
  
  it "should create a query for a node - relation - node pattern" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    qc = SparqlQueryCreator.new(pattern, nil)
    qs = qc.query_string
    nv1 = qc.pe_variable(pattern.nodes.first)    
    nv2 = qc.pe_variable(pattern.nodes.last)
    assert_equal qs, "SELECT ?#{nv1} ?#{nv2} WHERE { ?#{nv1} a <http://example.org/node> . ?#{nv2} a <http://example.org/node> . ?#{nv1} http://example.org/relation ?#{nv2} . }"
  end
  
  it "should create properly create queries for the different operators on attribute constraints" do
    pattern = FactoryGirl.create(:empty_pattern)
    pattern.pattern_elements << FactoryGirl.create(:plain_node, :pattern => pattern)
    regex_ac = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:regex], :node => pattern.nodes.first)
    qc = SparqlQueryCreator.new(pattern, nil)
    qs = qc.query_string
    nv = qc.pe_variable(pattern.nodes.first)
    acv = qc.pe_variable(regex_ac)
    expected = "SELECT ?#{nv} WHERE { ?#{nv} a <http://example.org/node> . ?#{nv} <#{regex_ac.rdf_type}> ?#{acv} . FILTER(regex(?#{acv}, 'hello world')) }"
    assert_equal expected, qs
  end
  
end