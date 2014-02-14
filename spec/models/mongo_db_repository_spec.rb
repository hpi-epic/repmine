require 'spec_helper'

describe MongoDbRepository do
  
  before(:each) do
    @mdb_repo = MongoDbRepository.new({:database_name => "sample_db", :name => "sample_db"})
    # make sure that we don't require a mongodb connection
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["collection1", "collection2", "fancy_collection"])}
  end
  
  it "should create a class for each collection" do
    classes = @mdb_repo.all_classes
    classes[0].name.should == "Collection1"
    classes[1].name.should == "Collection2"
    classes[2].name.should == "FancyCollection"    
  end
  
  it "should singularize collection names before they become class names" do
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["items"])}
    classes = @mdb_repo.all_classes
    classes.first.name.should == "Item"
  end
  
  it "should create a fancy url for the class. this needs to be based on configuration" do
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["items"])}
    classes = @mdb_repo.all_classes
    classes.first.uri.should == "http://hpi-web.de/ontologies/repmine/schemas/extracted/sample_db/Item"
  end
end