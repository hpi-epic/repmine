require 'rails_helper'

RSpec.describe Neo4jRepository, :type => :model do
  
  it "should properly build an ontology given certain information from the graph" do
    properties = {
      "AwesomeModel" => {"attribute1" => "String", "attribute2" => 2, "attribute3" => true},
      "AwesomeModel2" => {"attribute1" => "String", "attribute2" => 2, "attribute3" => true, "attribute4" => DateTime.now}
    }
    relationships = [
      ["AwesomeModel", "KNOWS", "AwesomeModel2", 1234],
      ["AwesomeModel2", "KNOWS_TOO", "AwesomeModel", 5678]
    ]
    repo = FactoryGirl.create(:neo4j_repository)
    repo.populate_ontology!(properties, relationships)
    assert_equal 2, repo.ontology.classes.size
    am = repo.ontology.classes.find{|cla| cla.name == "AwesomeModel"}
    am2 = repo.ontology.classes.find{|cla| cla.name == "AwesomeModel2"}
    assert_not_nil am
    assert_not_nil am2
    assert_equal 3, am.attributes.size
    assert_equal 4, am2.attributes.size
    assert am.attributes.all?{|attrib| attrib.domain == am}
    assert am2.attributes.all?{|attrib| attrib.domain == am2}    
    assert_equal 1, am.relations.size
    assert_equal "KNOWS", am.relations.first.name
    assert_equal am, am.relations.first.domain
  end
  
end
