require 'spec_helper'

describe MongoDbRepository do
  
  before(:each) do
    @mdb_repo = MongoDbRepository.create({:database_name => "sample_db", :name => "sample_db"})
    # make sure that we don't require a mongodb connection
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["collection1", "collection2", "fancy_collection"])}
  end
  
  def schema_info
    [
      {"_id" => {"key" => "root"}, "value" => {"type" => "String"}},
      {"_id" => {"key" => "random_attribute"}, "value" => {"type" => "Number"}},
      {"_id" => {"key" => "root_rel1"},"value" => {"type" => "null"}},      
      {"_id" => {"key" => "root_rel1.level1_attribute"}, "value" => {"type" => "String"}},
      {"_id" => {"key" => "root_rel1.level1_relation"}, "value" => {"type" => "Object"}},      
      {"_id" => {"key" => "root_rel1.level1_relation.attrib1"}, "value" => {"type" => "String"}},
      {"_id" => {"key" => "root_rel1.level1_relation.level2_relation"}, "value" => {"type" => "Array"}},      
      {"_id" => {"key" => "root_rel1.level1_relation.level2_relation.XX.attrib2"}, "value" => {"type" => "String"}}
    ]
  end
  
  it "should create a class for each collection" do
    allow(@mdb_repo).to receive(:get_schema_info){[]}    
    @mdb_repo.extract_ontology!
    classes = @mdb_repo.ontology.classes
    classes.size.should == 3
    classes.find{|c| c.name == "Collection1"}.should_not be_nil
    classes.find{|c| c.name == "Collection2"}.should_not be_nil
    classes.find{|c| c.name == "FancyCollection"}.should_not be_nil        
  end
  
  it "should singularize collection names before they become class names" do
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["items"])}
    allow(@mdb_repo).to receive(:get_schema_info){[]}
    @mdb_repo.extract_ontology!        
    classes = @mdb_repo.ontology.classes
    classes.first.name.should == "Item"
  end
  
  it "should create a fancy url for the class. this needs to be based on configuration" do
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["items"])}
    allow(@mdb_repo).to receive(:get_schema_info){[]}    
    @mdb_repo.extract_ontology!    
    classes = @mdb_repo.ontology.classes
    classes.first.url.should == "http://hpi-web.de/ns/ontologies/repmine/schemas/extracted/sample_db/Item"
  end
  
  it "it should find direct ancestors" do
    # "root" and "root_rel1"
    @mdb_repo.all_descendants(schema_info, "").size.should == schema_info.size
    @mdb_repo.all_descendants(schema_info, "root").size.should == 0
    @mdb_repo.all_descendants(schema_info, "root_rel1").size.should == 5
    @mdb_repo.all_descendants(schema_info, "root_rel1.level1_relation").size.should == 3    
  end
  
  it "should create a schema for the given info object returned by variety.js" do
    @mdb_repo.stub("db"){
      double("mongodb", {"collection_names" => ["collection1"]})
    }
    allow(@mdb_repo).to receive(:get_schema_info){schema_info}
    @mdb_repo.extract_ontology!    
    @mdb_repo.ontology.classes.size.should == 2
  end
end