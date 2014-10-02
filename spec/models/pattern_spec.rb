require 'rails_helper'

RSpec.describe Pattern, :type => :model do  
  it "should only remove unsaved elements upon 'reset'" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.update_attribute(:updated_at,Time.now)
    
    @node = @pattern.nodes.create!    
    AttributeConstraint.create!(:node => @node)
    RelationConstraint.create(:source_id => @node.id, :target_id => @node.id)
    
    nodes_before = Node.count
    ac_before = AttributeConstraint.count
    rc_before = RelationConstraint.count
    @pattern.reset!
    
    assert_equal (nodes_before - 1), Node.count
    assert_equal (ac_before - 1), AttributeConstraint.count
    assert_equal (rc_before - 1), RelationConstraint.count    
  end
  
  it "should revert unsaved changes for existing elements" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.update_attribute(:updated_at,Time.now)
    assert_not_equal "http://example2.org", @pattern.nodes.first.rdf_type
    @pattern.nodes.first.rdf_type = "http://example2.org"
    @pattern.reset!
    assert_not_equal "http://example2.org", @pattern.nodes.first.rdf_type
  end
  
  it "should not change its repository name after the first save" do
    @pattern = FactoryGirl.create(:pattern)
    res_before = @pattern.repository_name
    @pattern.save 
    assert_equal res_before, @pattern.repository_name    
  end
  
  it "should not remove updated nodes and constraints" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.update_attribute(:updated_at,Time.now)
    @pattern.nodes.first.rdf_type = "http://example2.org"
    @pattern.nodes.first.save
    @pattern.nodes.first.attribute_constraints.first.attribute_name = "http://example2.org"
    @pattern.nodes.first.attribute_constraints.first.save
    @pattern.nodes.first.source_relation_constraints.first.relation_type = "http://example2.org"
    @pattern.nodes.first.source_relation_constraints.first.save
    
    nodes_before = Node.count
    ac_before = AttributeConstraint.count
    rc_before = RelationConstraint.count
    @pattern.reset!
    
    assert_equal nodes_before, Node.count
    assert_equal ac_before, AttributeConstraint.count
    assert_equal rc_before, RelationConstraint.count
    
    assert_equal @pattern.nodes.first.attribute_constraints.first.attribute_name, "http://example2.org"
    assert_equal @pattern.nodes.first.source_relation_constraints.first.relation_type, "http://example2.org"
  end
  
  it "should find recent changes properly" do 
    @pattern = FactoryGirl.create(:pattern)
    @pattern.update_attribute(:updated_at,Time.now)    
    @new_node = @pattern.nodes.create()
    assert_equal @pattern.recent_changes[:nodes].include?(@new_node), true
    assert_equal @pattern.recent_changes[:nodes].size, 1
    @pattern.update_attribute(:updated_at,Time.now)    
    assert_equal @pattern.recent_changes[:nodes].size, 0
    @new_node.update_attribute(:updated_at,Time.now)
    assert_equal @pattern.recent_changes[:nodes].include?(@new_node), true
    assert_equal @pattern.recent_changes[:nodes].size, 1
    
    @pattern.nodes.first.attribute_constraints.first.update_attribute(:updated_at, Time.now)    
    assert_equal @pattern.recent_changes[:attributes].include?(@pattern.nodes.first.attribute_constraints.first), true
    assert_equal @pattern.recent_changes[:attributes].size, 1 
    @pattern.update_attribute(:updated_at,Time.now)     
    assert_equal @pattern.recent_changes[:attributes].size, 0     
    
    @pattern.nodes.first.source_relation_constraints.first.update_attribute(:updated_at, Time.now)
    assert_equal @pattern.recent_changes[:relations].include?(@pattern.nodes.first.source_relation_constraints.first), true
    assert_equal @pattern.recent_changes[:relations].size, 1
    @pattern.update_attribute(:updated_at,Time.now) 
    assert_equal @pattern.recent_changes[:relations].size, 0       
    
    @pattern.nodes.first.target_relation_constraints.first.update_attribute(:updated_at, Time.now)
    assert_equal @pattern.recent_changes[:relations].include?(@pattern.nodes.first.target_relation_constraints.first), false
    assert_equal 0, @pattern.recent_changes[:relations].size
  end
  
  it "should create a proper RDF graph for a simple pattern" do
    @pattern = FactoryGirl.create(:pattern)
    @graph = @pattern.rdf_graph
    
    # there is one graph pattern
    graph_pattern = query_graph_for_type(@graph, Vocabularies::GraphPattern.GraphPattern).first
    assert_not_nil graph_pattern
    # three pattern elements
    assert_equal 3, query_graph_for_type(@graph, Vocabularies::GraphPattern.PatternElement).size
    # and they are linked to the graph pattern
    res = query(@graph, {:ge => {Vocabularies::GraphPattern.belongsTo => graph_pattern}})    
    assert_equal 3, res.size
    
    nodes = query_graph_for_type(@graph, Vocabularies::GraphPattern.Node)
    assert_equal 1, nodes.size
    
    res = query(@graph, {nodes.first => {Vocabularies::GraphPattern.attributeConstraint => :ac}})
    assert_equal 1, res.size
    assert_equal @pattern.nodes.first.attribute_constraints.first.url, res.first[:ac]
    
    res = query(@graph, {nodes.first => {Vocabularies::GraphPattern.outgoingRelation => :orc}})
    assert_equal 1, res.size
    assert_equal @pattern.nodes.first.source_relation_constraints.first.url, res.first[:orc]
    
    res = query(@graph, {nodes.first => {Vocabularies::GraphPattern.incomingRelation => :irc}})
    assert_equal 1, res.size
    assert_equal @pattern.nodes.first.target_relation_constraints.first.url, res.first[:irc]
    
    ac_count = @pattern.nodes.inject(0){|x,node| x += node.attribute_constraints.size}
    assert_equal ac_count, query_graph_for_type(@graph, Vocabularies::GraphPattern.AttributeConstraint).size
    rc_count = @pattern.nodes.inject(0){|x,node| x += node.source_relation_constraints.size}
    assert_equal ac_count, query_graph_for_type(@graph, Vocabularies::GraphPattern.RelationConstraint).size
  end
  
  def query_graph_for_type(graph, rdf_type)
    results = []
    query = RDF::Query.new({:thing => {RDF.type  => rdf_type}})
    query.execute(graph){|solution| results << solution.thing}
    return results
  end

  def query(graph, query_hash)
    results = []
    query = RDF::Query.new(query_hash)
    query.execute(graph){|solution| results << solution}
    return results
  end

end