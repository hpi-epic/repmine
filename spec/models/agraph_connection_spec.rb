require 'rails_helper'
require_relative '../testfiles/test_ontology'

RSpec.describe AgraphConnection, :type => :model do
  
  # yeah, could make the tests rather slow, but we got those few seconds
  # why not mock? Because we need the reasoning capabilities...
  before :each do 
    @agc = AgraphConnection.new("__XX__TEST__")
    @agc.clear!
    insert_ontology!(@agc, TestOntology)
  end

  it "should find all superclasses" do
    supers = @agc.get_all_superclasses(TestOntology.ClassD)
    assert_equal 2, supers.size
    supers.should include(TestOntology.ClassC.to_s)
    supers.should include(TestOntology.ClassA.to_s)
    
    supers = @agc.get_all_superclasses(TestOntology.ClassA)
    assert_empty supers
  end
  
  it "should find attributes (aka DatatypeProperties) with a certain range" do 
    attribs = @agc.attributes_for(TestOntology.ClassA)
    assert_equal 1, attribs.size
    assert_equal TestOntology.attrib_1.to_s, attribs.first.url
    
    attribs = @agc.attributes_for(TestOntology.ClassB)
    assert_empty attribs
    
    attribs = @agc.attributes_for(TestOntology.ClassC)
    assert_equal 1, attribs.size
    assert_equal TestOntology.attrib_1.to_s, attribs.first.url    
  end
  
  it "should find relations from target to destination" do
    rels = @agc.relations_with(TestOntology.ClassA, TestOntology.ClassB)
    assert_equal 1, rels.size
    assert_equal TestOntology.relation1.to_s, rels.first.url
    rels = @agc.relations_with(TestOntology.ClassC, TestOntology.ClassB)
    assert_equal 1, rels.size
    assert_equal TestOntology.relation1.to_s, rels.first.url    
    assert_empty @agc.relations_with(TestOntology.ClassA, TestOntology.ClassA)
    rels = @agc.relations_with(TestOntology.ClassB, TestOntology.ClassC)
    assert_equal 1, rels.size
    assert_equal TestOntology.relation2.to_s, rels.first.url
    rels = @agc.relations_with(TestOntology.ClassA, TestOntology.ClassB)
    assert_equal 1, rels.size
    assert_equal TestOntology.relation1.to_s, rels.first.url    
  end

  it "should get the type hierarchy right" do
    th = @agc.type_hierarchy
    # two root classes
    assert_equal 2, th.size
    classA = th.find{|cl| cl.url == TestOntology.ClassA.to_s}
    assert_equal 1, classA.subclasses.size
    assert_equal TestOntology.ClassC.to_s, classA.subclasses.first.url
  end
  
  it "should return the right pattern element class for everything" do
    assert_equal Node, @agc.element_class_for_rdf_type(TestOntology.ClassA.to_s)
    assert_equal AttributeConstraint, @agc.element_class_for_rdf_type(TestOntology.attrib_1.to_s)
    assert_equal RelationConstraint, @agc.element_class_for_rdf_type(TestOntology.relation1.to_s)
    assert_equal PatternElement, @agc.element_class_for_rdf_type("http://jibbetgarnich/alsoechtnicht")
  end
  
  def insert_ontology!(ag, ont)
    stmts = []
    ont.each_statement{|stmt| stmts << stmt}
    ag.repository.insert(*stmts)
  end
end
