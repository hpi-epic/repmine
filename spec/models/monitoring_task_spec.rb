require 'rails_helper'

RSpec.describe MonitoringTask, :type => :model do

  before(:each) do
    @pattern = FactoryGirl.create(:pattern)
    @repo = FactoryGirl.create(:repository)
    @mt = FactoryGirl.create(:monitoring_task, measurable: @pattern, repository: @repo)
  end

  it "should determine whether to run the task" do
    expect(@mt.filename).to eq("Pattern_#{@pattern.id}_repo_#{@repo.id}")
    File.stub(:exist?).with(@mt.results_file("yml")){true}
    File.stub(:exist?).with(@mt.results_file("csv")){false}
    expect(@mt.has_latest_results?).to eq(false)
    File.stub(:exist?).with(@mt.results_file("csv")){true}
    expect(@mt.has_latest_results?).to eq(true)
  end

  it "should create mutliple ones without building duplicates" do
    tasks = MonitoringTask.create_multiple([@pattern.id, @pattern.id], @repo.id)
    expect(tasks.size).to eq(1)
    expect(MonitoringTask.count).to eq(1)
  end

  it "should call the measurable and store the results" do
    FileUtils.rm_rf(yml_file)
    FileUtils.rm_rf(csv_file)
    @mt.stub(:results_file).with("yml"){yml_file()}
    @mt.stub(:results_file).with("csv"){csv_file()}
    @pattern.stub(:run_on_repository){[[{"hello" => "world"}], "hello\r\nworld"]}
    @mt.run()
    expect(File.exist?(yml_file)).to be(true)
    expect(File.exist?(csv_file)).to be(true)
    expect(@mt.results.first["hello"]).to eq("world")
    expect(@mt.csv_result.start_with?("hello")).to be(true)
    expect(@mt.pretty_csv_name).to eq("sample_pattern-on-sample_repo.csv")
    expect(@mt.short_name).to eq("'#{@pattern.name}' on '#{@repo.name}'")
  end

  it "should enqueue a task" do
    expect(Delayed::Job.count).to eq(0)
    @mt.enqueue
    expect(Delayed::Job.count).to eq(1)
  end

  def yml_file
    Rails.root.join("spec", "testfiles", "mt.yml").to_s
  end

  def csv_file
    Rails.root.join("spec", "testfiles", "mt.csv").to_s
  end
end
