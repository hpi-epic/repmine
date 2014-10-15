require 'rails_helper'

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
  
  def insert_ontology!(ag, ont)
    stmts = []
    ont.each_statement{|stmt| stmts << stmt}
    ag.repository.insert(*stmts)
  end

  # ontology within the testcase you ask? Yes, locality of test data ;)
  class TestOntology < RDF::StrictVocabulary("http://example.org/test_ontology/")
    term :ClassA,
      label: "ClassA".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :ClassB,
      label: "ClassB".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :ClassC,
      label: "ClassC".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      :subClassOf => "testontology:ClassA".freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]      
    term :ClassD,
      label: "ClassD".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      :subClassOf => "testontology:ClassC".freeze,      
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    property :attrib_1,
      domain: "testontology:ClassA".freeze,
      label: "attrib_1".freeze,
      range: "xsd:string".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      type: "owl:DatatypeProperty".freeze     
    property :relation1,
      domain: "testontology:ClassA".freeze,
      label: "relation1".freeze,
      range: "testontology:ClassB".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      type: "owl:ObjectProperty".freeze       
    property :relation2,
      domain: "testontology:ClassB".freeze,
      label: "relation1".freeze,
      range: "testontology:ClassA".freeze,
      "rdfs:isDefinedBy" => %(testontology:).freeze,
      type: "owl:ObjectProperty".freeze      
  end
  
end
