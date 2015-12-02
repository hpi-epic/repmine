require 'rails_helper'

RSpec.describe Aggregation, :type => :model do

  before(:each) do
    @aggr = FactoryGirl.create(:aggregation)
    @repo = FactoryGirl.create(:repository)
    @target_node = FactoryGirl.create(:node, ontology: @repo.ontology)
    PatternElementMatch.create(:matched_element => @aggr.pattern_element, :matching_element => @target_node)
  end

  it "should be able to create a clone for a different repository" do
    aggr_clone = @aggr.translated_to(@repo)
    assert_equal @target_node, aggr_clone.pattern_element
  end

  it "should store translated aggregations in the DB" do
    first_clone = @aggr.translated_to(@repo)
    expect(first_clone).to_not eq(@aggr)
    second_clone = @aggr.translated_to(@repo)
    expect(second_clone).to eq(first_clone)
  end

  it "should call the substitutor" do
    assert_equal @target_node, @aggr.translated_to(@repo).pattern_element
  end

  it "should simply pass through the fixed stuff" do
    clone_old = @aggr.translated_to(@repo)
    @aggr.operation = :sum
    @aggr.save
    clone_new = @aggr.translated_to(@repo)
    expect(clone_new.operation).to eq(:sum)
  end

  it "should adapt if we changed the pattern element of the original aggregation" do
    clone_old = @aggr.translated_to(@repo)
    expect(clone_old.pattern_element).to eq(@target_node)
    new_target = FactoryGirl.create(:node, ontology: @repo.ontology)
    new_source = FactoryGirl.create(:node, ontology: @aggr.pattern_element.ontology)
    PatternElementMatch.create(:matched_element => new_source, :matching_element => new_target)
    @aggr.operation = :sum
    @aggr.pattern_element = new_source
    @aggr.save

    clone_new = @aggr.translated_to(@repo)
    expect(clone_new).to eq(clone_old)
    expect(clone_new.operation).to eq(:sum)
    expect(clone_new.pattern_element).to eq(new_target)
  end
end
