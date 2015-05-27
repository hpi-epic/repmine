require 'rails_helper'

RSpec.describe CypherQueryCreator, :type => :model do

  it "should create a simple one node query" do
    pattern = FactoryGirl.create(:node_only_pattern)
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    qv = query_variables(pattern, qc)    
    assert_equal "MATCH #{qv["nr1"]} RETURN #{qv["nv1"]}", qs
  end
  
  it "should create simple multi node queries" do
    pattern = FactoryGirl.create(:node_only_pattern)
    pattern.create_node!
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    qv = query_variables(pattern, qc)    
    assert_equal "MATCH #{qv["nr1"]}, #{qv["nr2"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}", qs
  end

  it "should create a valid query for a simple node - self-relation - node pattern" do
    pattern = FactoryGirl.create(:pattern)
    pattern.attribute_constraints.first.destroy
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    qv = query_variables(pattern, qc)
    assert_equal qs, "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr1"]} RETURN #{qv["nv1"]}"
  end

  it "should create a query for a node - relation - node pattern" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr2"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}", qs
  end
  
  it "should concat multiple connection through commas" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    new_node = pattern.create_node!
    new_rc = RelationConstraint.create(:source_id => pattern.nodes.first.id, :target_id => new_node.id)
    new_rc.rdf_type = "fancy_new_connection"
    
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr2"]}, #{qv["nr1"]}-#{qv["rel2"]}->#{qv["nr3"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}, #{qv["nv3"]}", qs
  end
  
  it "should create properly create queries for the different operators on attribute constraints" do
    pattern = FactoryGirl.create(:empty_pattern)
    pattern.create_node!
    regex_ac = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:regex], :node => pattern.nodes.first, :value => "/hello world/")
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]} WHERE #{qv["att1"]} =~ #{regex_ac.value} RETURN #{qv["nv1"]}", qs
  end  
  
  def query_variables(pattern, qc)
    qv = {}
    pattern.nodes.each_with_index do |node, i|
      qv["nv#{i+1}"] = qc.pe_variable(node)
      qv["nr#{i+1}"] = qc.node_reference(node)
    end
    pattern.relation_constraints.each_with_index do |rc, i|
      qv["rel#{i+1}"] = qc.relation_reference(rc)
    end
    pattern.attribute_constraints.each_with_index do |ac, i|
      qv["att#{i+1}"] = qc.pe_variable(ac.node).to_s + "." + ac.rdf_type
    end
    return qv
  end

  it "should incorporate self-introduced variables" do
    pattern = FactoryGirl.create(:empty_pattern)
    pattern.pattern_elements << FactoryGirl.create(:plain_node, :pattern => pattern)
    var_ac1 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:var], :node => pattern.nodes.first, :value => "?name")
    var_ac2 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:equals], :node => pattern.nodes.first, :value => "?name")
    qc = CypherQueryCreator.new(pattern)
    qs = qc.query_string
    nv = qc.pe_variable(pattern.nodes.first)
    ac1v = qc.pe_variable(var_ac1)
    ac2v = qc.pe_variable(var_ac2)
    expected = "SELECT ?#{nv} WHERE { ?#{nv} a <http://example.org/node> . ?#{nv} <#{var_ac1.rdf_type}> ?name . ?#{nv} <#{var_ac2.rdf_type}> ?#{ac2v} . FILTER(?#{ac2v} = ?name) }"
  #  assert_equal expected, qs
  end

end