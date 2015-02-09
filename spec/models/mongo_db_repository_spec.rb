# == Schema Information
#
# Table name: repositories
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  db_name       :string(255)
#  db_username   :string(255)
#  db_password   :string(255)
#  host          :string(255)
#  port          :integer
#  description   :text
#  ontology_id   :integer
#  type          :string(255)
#  rdbms_type_cd :integer
#

require 'rails_helper'

RSpec.describe MongoDbRepository, :type => :model do

  before(:each) do
    @mdb_repo = MongoDbRepository.create({:db_name => "sample_db", :name => "sample_db"})
    @mdb_repo.ontology.remove_local_copy!
    # make sure that we don't require a mongodb connection
    @mdb_repo.stub("db"){double("mongodb", "collection_names" => ["collection1", "collection2", "fancy_collection"])}
  end

  after(:each) do
    @mdb_repo.ontology.remove_local_copy!
  end

  def schema_info
    [
      {"_id" => {"key" => "root"}, "value" => {"type" => "String"}},
      {"_id" => {"key" => "random_attribute"}, "value" => {"type" => "Number"}},
      {"_id" => {"key" => "root_rel1"},"value" => {"type" => "Object"}},
      {"_id" => {"key" => "root_rel1.level1_attribute"}, "value" => {"type" => "String"}},
      {"_id" => {"key" => "root_rel1.level1_relation"}, "value" => {"type" => "Object"}},
      {"_id" => {"key" => "root_rel1.level1_relation.attrib1"}, "value" => {"type" => "String"}},
      {"_id" => {"key" => "root_rel1.level1_relation.level2_relation"}, "value" => {"type" => "Array"}},
      {"_id" => {"key" => "root_rel1.level1_relation.level2_relation.attrib2"}, "value" => {"type" => "String"}}
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
    classes.first.url.should == ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:extracted_ontologies_path] + "sample_db_#{@mdb_repo.id}/Item"
  end

  it "should create a schema for the given info object returned by variety.js" do
    @mdb_repo.stub("db"){double("mongodb", {"collection_names" => ["collection1"]})}
    allow(@mdb_repo).to receive(:get_schema_info){schema_info}
    @mdb_repo.extract_ontology!
    classes = @mdb_repo.ontology.classes
    classes.size.should == 1
    c1 = classes.find{|c| c.name == "Collection1"}
    # only the direct attributes + arrays as we maybe have to query their size
    c1.attributes.size.should == 6
  end

  it "should create a local file for the given info object" do
    @mdb_repo.stub("db"){double("mongodb", {"collection_names" => ["collection1"]})}
    Ontology.any_instance.unstub(:download!)
    allow(@mdb_repo).to receive(:get_schema_info){schema_info}
    @mdb_repo.extract_ontology!
    graph = RDF::Graph.load(@mdb_repo.ontology.local_file_path)
    assert graph.size > 1
  end
end
