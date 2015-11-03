require 'rails_helper'

RSpec.describe Pattern, :type => :model do

  it "should create a proper RDF graph for a simple pattern" do
    pattern = FactoryGirl.create(:pattern)
    graph = pattern.rdf_graph

    # there is one graph pattern
    graph_pattern = query_graph_for_type(graph, Vocabularies::GraphPattern.GraphPattern).first
    assert_not_nil graph_pattern
    # three pattern elements
    assert_equal 3, query_graph_for_type(graph, Vocabularies::GraphPattern.PatternElement).size
    # and they are linked to the graph pattern
    res = query(graph, {:ge => {Vocabularies::GraphPattern.belongsTo => graph_pattern}})
    assert_equal 3, res.size

    nodes = query_graph_for_type(graph, Vocabularies::GraphPattern.Node)
    assert_equal 1, nodes.size

    res = query(graph, {nodes.first => {Vocabularies::GraphPattern.attributeConstraint => :ac}})
    assert_equal 1, res.size
    assert_equal pattern.nodes.first.attribute_constraints.first.url, res.first[:ac]

    res = query(graph, {nodes.first => {Vocabularies::GraphPattern.outgoingRelation => :orc}})
    assert_equal 1, res.size
    assert_equal pattern.nodes.first.source_relation_constraints.first.url, res.first[:orc]

    res = query(graph, {nodes.first => {Vocabularies::GraphPattern.incomingRelation => :irc}})
    assert_equal 1, res.size
    assert_equal pattern.nodes.first.target_relation_constraints.first.url, res.first[:irc]

    ac_count = pattern.nodes.inject(0){|x,node| x += node.attribute_constraints.size}
    assert_equal ac_count, query_graph_for_type(graph, Vocabularies::GraphPattern.AttributeConstraint).size
    rc_count = pattern.nodes.inject(0){|x,node| x += node.source_relation_constraints.size}
    assert_equal ac_count, query_graph_for_type(graph, Vocabularies::GraphPattern.RelationConstraint).size
  end

  it "should properly link all elements to the pattern for node only patterns" do
    pattern = FactoryGirl.create(:node_only_pattern)
    assert_not_nil Node.all.find{|n| n.pattern == pattern}
    assert_equal 1, pattern.pattern_elements.size
  end

  it "should add a node" do
    pattern = FactoryGirl.create(:node_only_pattern)    #
    before = pattern.pattern_elements.size
    new_node = pattern.create_node!(pattern.ontologies.first)
    pattern.pattern_elements.reload
    assert_equal before + 1, pattern.pattern_elements.size
    assert_equal new_node, pattern.nodes.last
  end

  it "should properly link all elements to the pattern for simple patterns" do
    pattern = FactoryGirl.create(:pattern)
    assert_not_nil Node.all.find{|n| n.pattern == pattern}
    assert_not_nil AttributeConstraint.all.find{|n| n.pattern == pattern}
    assert_not_nil RelationConstraint.all.find{|n| n.pattern == pattern}
    assert_equal 3, pattern.pattern_elements.size
  end

  it "should determine equality of very simple patterns" do
    p1 = FactoryGirl.create(:empty_pattern)
    p2 = FactoryGirl.create(:empty_pattern)
    assert p1.equal_to?(p2)
  end

  it "should determine similar n_r_n patterns" do
    p1 = n_r_n_pattern(FactoryGirl.create(:ontology), "http://example.org/n1", "http://example.org/r1", "http://example.org/n2")
    p2 = n_r_n_pattern(FactoryGirl.create(:ontology), "http://example.org/n1", "http://example.org/r1", "http://example.org/n2")
    assert p1.equal_to?(p2)
  end

  it "should determine missing links" do
    p1 = FactoryGirl.create(:pattern)
    p1.relation_constraints.first.destroy
    assert !p1.equal_to?(FactoryGirl.create(:pattern))
  end

  it "should return a proper layout for the pattern using graphviz" do
    p1 = FactoryGirl.create(:pattern)
    graph = p1.graphviz_graph
    graph.output(:png => Rails.root.join("spec/testfiles/pattern_graph.png"))
  end

  it "should properly rebuild a pattern from a graph" do
    cc = FactoryGirl.build(:complex_correspondence)

    om = OntologyMatcher.new(cc.onto1, cc.onto2)
    om.alignment_repo.clear!
    om.insert_graph_pattern_ontology!
    om.add_correspondence!(cc)

    pattern_node = nil
    om.alignment_graph.build_query() do |q|
      q.pattern [cc.resource, Vocabularies::Alignment.entity2, :pattern]
    end.run do |solution|
      pattern_node = solution[:pattern]
    end
    assert_not_nil pattern_node

    pattern = Pattern.from_graph(om.alignment_graph, pattern_node, cc.onto2)
    assert_equal 3, pattern.pattern_elements.size
    pattern.pattern_elements.each do |pe|
      assert pe.valid?, "#{pe.class} (#{pe.rdf_type}) is invalid: #{pe.errors.full_messages.join(", ")}"
    end
  end

  it "should find matching elements for "

  def n_r_n_pattern(ontology, source_class, relation_type, target_class, name = "Generic N_R_N")
    p = Pattern.create(name: name, description: "Generic")
    p.ontologies << ontology
    source_node = p.create_node!(p.ontologies.first)
    source_node.rdf_type = source_class
    target_node = p.create_node!(p.ontologies.first)
    target_node.rdf_type = target_class
    relation = RelationConstraint.create(:source_id => source_node.id, :target_id => target_node.id)
    relation.rdf_type = relation_type
    return p
  end

  def n_a_pattern(ontology, attribute_type, source_class, name)
    p = Pattern.create(name: name, description: "Generic")
    p.ontologies << ontology
    source_node = p.create_node!(p.ontologies.first)
    source_node.rdf_type = source_class
    ac = source_node.attribute_constraints.create
    ac.rdf_type = attribute_type
    return p
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
