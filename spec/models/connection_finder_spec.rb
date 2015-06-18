require 'rails_helper'

RSpec.describe ConnectionFinder, :type => :model do
  
  before(:each) do
    @cf = ConnectionFinder.new
  end
  
  it "should provide the obvious choices for attribute constraints" do
    [[1, "node", 2],[1, "maps_to", 3],[2,"maps_to",4],[4,"is_a","Node"]].each do |stmt|
      @cf.engine << stmt
    end
    assert_equal 1, @cf.target_node_ids(3).size
    assert_equal 4, @cf.target_node_ids(3).first
  end
  
  it "should provide the obvious choices for relation constraints" do
    [[1,"source",2],[1,"target",3],[1,"maps_to",4],[2,"maps_to",5],[3,"maps_to",6],[6,"is_a","Node"],[5,"is_a","Node"]].each do |stmt|
      @cf.engine << stmt
    end
    assert_equal 1, @cf.get_relation_node_ids(4,"source").size
    assert_equal 5, @cf.get_relation_node_ids(4,"source").first
    assert_equal 1, @cf.get_relation_node_ids(4,"target").size
    assert_equal 6, @cf.get_relation_node_ids(4,"target").first    
  end
  
end