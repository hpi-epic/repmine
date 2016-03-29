require 'rails_helper'

RSpec.describe MonitoringTask, :type => :model do

  before(:each) do
    @repo = FactoryGirl.create(:repository)
    @pattern = FactoryGirl.create(:pattern, ontologies: [@repo.ontology])
    @mt = FactoryGirl.create(:monitoring_task, measurable: @pattern, repository: @repo)
  end

  it "should determine whether to run the task" do
    expect(@mt.filename).to eq("Pattern_#{@pattern.id}_repo_#{@repo.id}")
    File.stub(:exist?).with(@mt.results_file("json")){true}
    expect(@mt.has_latest_results?).to eq(true)
    File.stub(:exist?).with(@mt.results_file("json")){false}
    expect(@mt.has_latest_results?).to eq(false)
  end

  it "should create mutliple ones without building duplicates" do
    tasks = MonitoringTask.create_multiple([@pattern.id, @pattern.id], @repo.id)
    expect(tasks.size).to eq(1)
    expect(MonitoringTask.count).to eq(1)
  end

  it "should call the measurable and store the results" do
    FileUtils.rm_rf(json_file)
    @mt.stub(:results_file).with("json"){json_file()}
    @pattern.stub(:run){[{"hello" => "world"}]}
    @mt.run()
    expect(File.exist?(json_file)).to be(true)
    expect(@mt.results.first["hello"]).to eq("world")
  end

  it "should enqueue a task" do
    expect(Delayed::Job.count).to eq(0)
    @mt.enqueue
    expect(Delayed::Job.count).to eq(1)
  end

  it "should pass custom attributes all the way to query creation" do
    before = @pattern.attribute_constraints.size
    rdf = "http://example.org/sneaky_attribute"
    ac = FactoryGirl.create(:attribute_constraint, monitoring_task_id: @mt.id, node: @pattern.nodes.first, rdf_type: rdf)
    expect(@pattern.attribute_constraints.size).to eq(before)
    expect(@pattern.attribute_constraints(@mt.id).size).to eq(before + 1)
    expect(@mt.query(@pattern)).to include(rdf)
  end

  def json_file
    Rails.root.join("spec", "testfiles", "mt.json").to_s
  end
end