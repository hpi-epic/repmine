require 'rails_helper'

RSpec.describe PatternElement, :type => :model do

  it "should overwrite simple rdf_types" do
    @pe = FactoryGirl.create(:pattern_element)
    assert_equal "http://example.org/generic_element", @pe.rdf_type
    @pe.rdf_type = "http://example.org/MyType2"
    assert_equal "http://example.org/MyType2", @pe.rdf_type
  end

  it "should also overwrite complex ones" do
    @pe = FactoryGirl.create(:pattern_element)
    @pe.type_expression.update_attributes(:operator => OwlClass::SET_OPS[:not])
    assert_equal "#{OwlClass::SET_OPS[:not]}http://example.org/generic_element", @pe.rdf_type
    assert_equal false, @pe.type_expression.is_simple?
    @pe.rdf_type = "http://example.org/MyType2"
    assert_equal "http://example.org/MyType2", @pe.rdf_type
  end
  
  it "should properly detect equality of two generic pattern elements" do
    pe1 = FactoryGirl.create(:pattern_element, :pattern => FactoryGirl.create(:empty_pattern))    
    pe2 = FactoryGirl.create(:pattern_element, :pattern => FactoryGirl.create(:empty_pattern))        
    assert pe1.equal_to?(pe2)
  end
  
  it "should raise an exception when comparing two elements of the same pattern" do
    pattern = FactoryGirl.create(:empty_pattern)
    pe1 = FactoryGirl.create(:pattern_element, :pattern => pattern)    
    pe2 = FactoryGirl.create(:pattern_element, :pattern => pattern)    
    expect{pe1.equal_to?(pe2)}.to raise_error(PatternElement::ComparisonError)
  end
  
  it "should rebuild a pattern element's element type from a graph" do
    g = RDF::Graph.new
    n = RDF::Node.new
    g << [n, Vocabularies::GraphPattern.elementType, "http://example.org/node"]
    g << [RDF::Node.new, Vocabularies::GraphPattern.elementType, "http://example.org/not_a_node"]
    node = Node.new()
    node.rdf_node = n
    node.rebuild!(g)
    assert_equal "http://example.org/node", node.rdf_type
  end
  
  it "should rebuild a pattern elements's literal values from a graph" do
    g = RDF::Graph.new
    n = RDF::Node.new
    g << [n, Vocabularies::GraphPattern.attributeValue, RDF::Literal.new(5)]
    rel_const = AttributeConstraint.new()
    rel_const.rdf_node = n
    rel_const.rebuild!(g)
    assert_equal 5, rel_const.value
  end
  
  it "should rebuild a pattern element's connection to element collections" do
    n1 = RDF::Node.new
    n2 = RDF::Node.new
    n3 = RDF::Node.new
    p = Pattern.new
    g = RDF::Graph.new
    g << [n1, Vocabularies::GraphPattern.attributeConstraint, n2]
    g << [n1, Vocabularies::GraphPattern.attributeConstraint, n3]
    ac = AttributeConstraint.new()
    ac.rdf_node = n2
    ac.pattern = p
    ac2 = AttributeConstraint.new()
    ac2.rdf_node = n3
    ac2.pattern = p  
    node = Node.new
    node.rdf_node = n1
    node.pattern = p
    p.pattern_elements = [node, ac, ac2]
    
    node.rebuild!(g)
    assert_equal 2, node.attribute_constraints.size
    assert_include node.attribute_constraints, ac
    assert_include node.attribute_constraints, ac2    
  end
  
  it "should also rebuild single connections" do 
    g = RDF::Graph.new
    n1 = RDF::Node.new
    n2 = RDF::Node.new
    p = Pattern.new
    g << [n2, Vocabularies::GraphPattern.sourceNode, n1]
    node = Node.new
    node.rdf_node = n1
    node.pattern = p
    rc = RelationConstraint.new
    rc.rdf_node = n2
    rc.pattern = p
    p.pattern_elements = [node, rc]    
    rc.rebuild!(g)
    assert_equal node, rc.source
  end
  
  it "should determine that a variable reference does not mean it is a variable" do
    ac1 = FactoryGirl.build(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:var], :value => "?name")
    ac2 = FactoryGirl.build(:attribute_constraint, :operator => AttributeConstraint::OPERATORS[:equals], :value => "?name")
    
    assert ac1.is_variable?
    assert !ac2.is_variable?
    assert ac2.refers_to_variable?
    assert !ac1.refers_to_variable?
  end
end
