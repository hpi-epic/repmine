require 'rails_helper'

RSpec.describe SparqlQueryCreator, :type => :model do

  it "should create a simple one node query" do
    pattern = FactoryGirl.create(:node_only_pattern)
    qc = SparqlQueryCreator.new(pattern)
    qs = qc.query_string
    assert_not_nil qs
    pe_variable = qc.pe_variable(pattern.nodes.first)
    assert_equal "SELECT ?#{pe_variable} WHERE { ?#{pe_variable} a <#{pattern.nodes.first.rdf_type}> . }", qs
  end

  it "should create a valid query for a simple node - self-relation - node pattern" do
    pattern = FactoryGirl.create(:pattern)
    qc = SparqlQueryCreator.new(pattern)
    qs = qc.query_string
    n1 = pattern.nodes.first
    r1 = pattern.relation_constraints.first
    ac1 = pattern.attribute_constraints.first
    nv = qc.pe_variable(n1)
    assert_equal "SELECT ?#{nv} WHERE { ?#{nv} a <#{n1.rdf_type}> . ?#{nv} <#{r1.rdf_type}> ?#{nv} . ?#{nv} <#{ac1.rdf_type}> \"hello world\" . }", qs
  end

  it "should create a query for a node - relation - node pattern" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    qc = SparqlQueryCreator.new(pattern)
    qs = qc.query_string
    n1 = pattern.nodes.first
    n2 = pattern.nodes.last
    r1 = pattern.relation_constraints.first
    nv1 = qc.pe_variable(n1)
    nv2 = qc.pe_variable(n2)
    assert_equal "SELECT ?#{nv1} ?#{nv2} WHERE { ?#{nv1} a <#{n1.rdf_type}> . ?#{nv2} a <#{n2.rdf_type}> . ?#{nv1} <#{r1.rdf_type}> ?#{nv2} . }", qs
  end

  it "should create properly create queries for the different operators on attribute constraints" do
    pattern = FactoryGirl.create(:empty_pattern)
    pattern.pattern_elements << FactoryGirl.create(:plain_node)
    regex_ac = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:regex], :node => pattern.nodes.first)
    qc = SparqlQueryCreator.new(pattern)
    qs = qc.query_string
    n1 = pattern.nodes.first
    nv = qc.pe_variable(n1)
    acv = qc.pe_variable(regex_ac)
    expected = "SELECT ?#{nv} WHERE { ?#{nv} a <#{n1.rdf_type}> . ?#{nv} <#{regex_ac.rdf_type}> ?#{acv} . FILTER(regex(?#{acv}, \"hello world\")) }"
    assert_equal expected, qs
  end

  it "should incorporate self-introduced variables" do
    pattern = FactoryGirl.create(:empty_pattern)
    pattern.pattern_elements << FactoryGirl.create(:plain_node)
    var_ac1 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:var], :node => pattern.nodes.first, :value => "?name")
    var_ac2 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:equals], :node => pattern.nodes.first, :value => "?name")
    qc = SparqlQueryCreator.new(pattern)
    qs = qc.query_string
    n1 = pattern.nodes.first
    nv = qc.pe_variable(n1)
    nv2 = qc.pe_variable(pattern.attribute_constraints.first)
    ac1v = qc.pe_variable(var_ac1)
    ac2v = qc.pe_variable(var_ac2)
    expected = "SELECT ?#{nv} ?#{nv2} WHERE { ?#{nv} a <#{n1.rdf_type}> . ?#{nv} <#{var_ac1.rdf_type}> ?name . ?#{nv} <#{var_ac2.rdf_type}> ?#{ac2v} . FILTER(?#{ac2v} = ?name) }"
    assert_equal expected, qs
  end

  it "should include aggregations" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    agg = FactoryGirl.create(:count_aggregation, :pattern_element => pattern.nodes.last, alias_name: "NodeCount")
    qc = SparqlQueryCreator.new(pattern, [agg])
    n1 = pattern.nodes.first
    n2 = pattern.nodes.last
    r1 = pattern.relation_constraints.first
    nv1 = qc.pe_variable(n1)
    nv2 = qc.pe_variable(n2)

    expected = "SELECT (COUNT(?#{nv2}) AS ?NodeCount) WHERE { ?#{nv1} a <#{n1.rdf_type}> . ?#{nv2} a <#{n2.rdf_type}> . ?#{nv1} <#{r1.rdf_type}> ?#{nv2} . }"
    assert_equal expected, qc.query_string

    agg2 = FactoryGirl.create(:aggregation, :pattern_element => pattern.nodes.first, alias_name: "NodeGroup")
    expected = "SELECT ?#{nv1} AS ?NodeGroup (COUNT(?#{nv2}) AS ?NodeCount) WHERE { ?#{nv1} a <#{n1.rdf_type}> . ?#{nv2} a <#{n2.rdf_type}> . ?#{nv1} <#{r1.rdf_type}> ?#{nv2} . } GROUP BY ?#{nv1}"
    qc = SparqlQueryCreator.new(pattern, [agg2, agg])
    assert_equal expected, qc.query_string
  end

  it "should include pass-through aggregations" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    agg = FactoryGirl.create(:count_aggregation, :pattern_element => pattern.nodes.last, alias_name: "NodeCount", operation: nil)
    qc = SparqlQueryCreator.new(pattern, [agg])
    n1 = pattern.nodes.first
    n2 = pattern.nodes.last
    r1 = pattern.relation_constraints.first
    nv1 = qc.pe_variable(n1)
    nv2 = qc.pe_variable(n2)

    expected = "SELECT ?#{nv2} AS ?NodeCount WHERE { ?#{nv1} a <#{n1.rdf_type}> . ?#{nv2} a <#{n2.rdf_type}> . ?#{nv1} <#{r1.rdf_type}> ?#{nv2} . }"
    assert_equal expected, qc.query_string
  end
end