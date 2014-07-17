require 'spec_helper'

describe Pattern do
  it "should only remove unsaved elements upon 'reset'" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.save!
    @node = @pattern.nodes.create!
    AttributeConstraint.create!(:node => @node)
    @node.create_relation_constraint_with_target!(@node)
    
    nodes_before = Node.count
    ac_before = AttributeConstraint.count
    rc_before = RelationConstraint.count
    @pattern.reset!
    
    assert_equal (nodes_before - 1), Node.count
    assert_equal (ac_before - 1), AttributeConstraint.count
    assert_equal (rc_before - 1), RelationConstraint.count    
  end
  
  it "should revert unsaved changes for existing elements" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.save!
    assert_not_equal "http://example2.org", @pattern.nodes.first.rdf_type
    @pattern.nodes.first.rdf_type = "http://example2.org"
    @pattern.reset!
    assert_not_equal "http://example2.org", @pattern.nodes.first.rdf_type
  end
end
