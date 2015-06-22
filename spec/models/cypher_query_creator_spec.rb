require 'rails_helper'

RSpec.describe CypherQueryCreator, :type => :model do

  before :each do
    AttributeConstraint.any_instance.stub(:value_type => RDF::XSD.string)
    AgraphConnection.any_instance.stub(:label_for_resource){|arg1, arg2| arg2.split("/").last}
  end

  it "should create a simple one node query" do
    pattern = FactoryGirl.create(:node_only_pattern)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)    
    assert_equal "MATCH #{qv["nr1"]} RETURN #{qv["nv1"]}", qc.query_string
  end
  
  it "should create simple multi node queries" do
    pattern = FactoryGirl.create(:node_only_pattern)
    pattern.create_node!(pattern.ontologies.first)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)    
    assert_equal "MATCH #{qv["nr1"]}, #{qv["nr2"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}", qc.query_string
  end

  it "should create a valid query for a simple node - self-relation - node pattern" do
    pattern = FactoryGirl.create(:pattern)
    pattern.attribute_constraints.first.destroy
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr1"]} RETURN #{qv["nv1"]}", qc.query_string
  end

  it "should create a query for a node - relation - node pattern" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr2"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}", qc.query_string
  end
  
  it "should concat multiple connection through commas" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    new_node = pattern.create_node!(pattern.ontologies.first)
    new_rc = FactoryGirl.create(:relation_constraint, :source_id => pattern.nodes.first.id, :target_id => new_node.id)
    new_rc.rdf_type = "fancy_new_connection"
    pattern.pattern_elements.reload    
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr2"]}, #{qv["nr1"]}-#{qv["rel2"]}->#{qv["nr3"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}, #{qv["nv3"]}", qc.query_string
  end
  
  it "should properly create regex queries" do
    pattern = FactoryGirl.create(:empty_pattern)
    pattern.create_node!(pattern.ontologies.first)
    regex_ac = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:regex], :node => pattern.nodes.first, :value => "/hello world/")
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]} WHERE #{qv["att1"]} #{AttributeConstraint::OPERATORS[:regex]} 'hello world' RETURN #{qv["nv1"]}", qc.query_string
  end
  
  it "should incorporate self-introduced variables for attributes" do
    pattern = FactoryGirl.create(:empty_pattern)
    node1 = FactoryGirl.create(:plain_node, :pattern => pattern)
    node2 = FactoryGirl.create(:plain_node, :pattern => pattern)    
    var_ac1 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:var], :node => node1, :value => "?name")
    var_ac2 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:equals], :node => node2, :value => "?name")
    
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    expected = "MATCH #{qv["nr1"]}, #{qv["nr2"]} WHERE #{qv["att2"]} = #{qv["att1"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}"
    assert_equal expected, qc.query_string
  end
  
  it "should include aggregations" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    pattern.nodes.last.aggregation = FactoryGirl.create(:count_aggregation)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    assert_equal "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr2"]} RETURN #{qv["nv1"]}, count(#{qv["nv2"]})", qc.query_string
  end

  it "should incorporate self-introduced variables" do
    pattern = FactoryGirl.create(:empty_pattern)
    n1 = FactoryGirl.create(:plain_node, :pattern => pattern)
    var_ac1 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:var], :node => n1, :value => "?name")
    var_ac1.create_aggregation(:operation => :sum)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    expected = "MATCH #{qv["nr1"]} WITH #{qv["nv1"]}, #{qv["att1"]} AS name RETURN sum(#{var_ac1.variable_name})"
    assert_equal expected, qc.query_string
  end
  
  it "should not return the node if we already group by an attribute" do
    pattern = FactoryGirl.create(:empty_pattern)
    n1 = FactoryGirl.create(:plain_node, :pattern => pattern)
    var_ac1 = FactoryGirl.create(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:var], :node => n1, :value => "?name")    
    agg = FactoryGirl.create(:aggregation, :pattern_element => var_ac1)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    expected = "MATCH #{qv["nr1"]} WITH #{qv["nv1"]}, #{qv["att1"]} AS name RETURN name"
    assert_equal expected, qc.query_string
  end
  
  it "should properly name relations" do
    pattern = FactoryGirl.create(:n_r_n_pattern)
    qc = CypherQueryCreator.new(pattern)
    qv = query_variables(pattern, qc)
    expected = "MATCH #{qv["nr1"]}-#{qv["rel1"]}->#{qv["nr2"]} RETURN #{qv["nv1"]}, #{qv["nv2"]}"
    assert_equal expected, qc.query_string
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
      qv["att#{i+1}"] = qc.attribute_reference(ac)
    end
    return qv
  end

end
