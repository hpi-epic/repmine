# == Schema Information
#
# Table name: patterns
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  ontology_id :integer
#  type        :string(255)
#  pattern_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe Pattern, :type => :model do

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

  it "should properly link all elements to the pattern for node only patterns" do
    @pattern = FactoryGirl.create(:node_only_pattern)
    assert_not_nil Node.all.find{|n| n.pattern == @pattern}
    assert_equal 1, @pattern.pattern_elements.size
  end

  it "should properly link all elements to the pattern for simple patterns" do
     @pattern = FactoryGirl.create(:pattern)
     assert_not_nil Node.all.find{|n| n.pattern == @pattern}
     assert_not_nil AttributeConstraint.all.find{|n| n.pattern == @pattern}
     assert_not_nil RelationConstraint.all.find{|n| n.pattern == @pattern}
     assert_equal 3, @pattern.pattern_elements.size
   end

  it "should properly return all unmatched concepts" do
    @pattern = FactoryGirl.create(:pattern)
    # should be http://example.org/node|relation|attribute
    assert_equal 3, @pattern.concept_count
    OntologyMatcher.any_instance.stub(:match! => true, :correspondences_for_concept => [], :correspondences_for_pattern => [])
    assert_equal 3, @pattern.unmatched_concepts(Ontology.first).size
    # create the correspondence
    correspondence = FactoryGirl.create(:ontology_correspondence)
    correspondence.input_elements = [@pattern.nodes.first]
    correspondence.output_elements = [PatternElement.for_rdf_type(@pattern.nodes.first.rdf_type + "_matched")]
    correspondence.save
    # now only return this one correspondence, which should eliminate http://example.org/node from the unmatched list
    OntologyMatcher.any_instance.stub(:match! => true, :get_substitutes_for => [correspondence])
    assert_equal 2, @pattern.unmatched_concepts(Ontology.first).size
    assert_not_include @pattern.unmatched_concepts(Ontology.first), @pattern.nodes.first.rdf_type + "_matched"
  end
  
  it "should determine equality of very simple patterns" do
    p1 = FactoryGirl.create(:empty_pattern)
    p2 = FactoryGirl.create(:empty_pattern)
    assert p1.equal_to?(p2)
  end
  
  it "should determine similar n_r_n patterns" do
    p1 = Pattern.n_r_n_pattern(FactoryGirl.create(:ontology), "http://example.org/n1", "http://example.org/r1", "http://example.org/n2")
    p2 = Pattern.n_r_n_pattern(FactoryGirl.create(:ontology), "http://example.org/n1", "http://example.org/r1", "http://example.org/n2")
    assert p1.equal_to?(p2)
  end
  
  it "should determine missing links" do
    p1 = FactoryGirl.create(:pattern)
    p1.relation_constraints.first.destroy
    assert !p1.equal_to?(FactoryGirl.create(:pattern))
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
