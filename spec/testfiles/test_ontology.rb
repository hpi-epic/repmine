# ontology within the testcase you ask? Yes, locality of test data ;)
class TestOntology < RDF::StrictVocabulary("http://example.org/test_ontology/")

  term "",
    label: "Test Ontology".freeze,
    type: ["owl:Ontology".freeze]
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
