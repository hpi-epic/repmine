require 'rails_helper'

RSpec.describe Pattern, :type => :model do  
  it "should only remove unsaved elements upon 'reset'" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.update_attribute(:updated_at,Time.now)
    
    @node = @pattern.nodes.create!    
    AttributeConstraint.create!(:node => @node)
    RelationConstraint.create(:source_id => @node.id, :target_id => @node.id)
    
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
    @pattern.update_attribute(:updated_at,Time.now)
    assert_not_equal "http://example2.org", @pattern.nodes.first.rdf_type
    @pattern.nodes.first.rdf_type = "http://example2.org"
    @pattern.reset!
    assert_not_equal "http://example2.org", @pattern.nodes.first.rdf_type
  end
  
  it "should not change its repository name after the first save" do
    @pattern = FactoryGirl.create(:pattern)
    res_before = @pattern.repository_name
    @pattern.save 
    assert_equal res_before, @pattern.repository_name    
  end
  
  it "should not remove updated nodes and constraints" do
    @pattern = FactoryGirl.create(:pattern)
    @pattern.update_attribute(:updated_at,Time.now)
    @pattern.nodes.first.rdf_type = "http://example2.org"
    @pattern.nodes.first.save
    @pattern.nodes.first.attribute_constraints.first.attribute_name = "http://example2.org"
    @pattern.nodes.first.attribute_constraints.first.save
    @pattern.nodes.first.source_relation_constraints.first.relation_type = "http://example2.org"
    @pattern.nodes.first.source_relation_constraints.first.save
    
    nodes_before = Node.count
    ac_before = AttributeConstraint.count
    rc_before = RelationConstraint.count
    @pattern.reset!
    
    assert_equal nodes_before, Node.count
    assert_equal ac_before, AttributeConstraint.count
    assert_equal rc_before, RelationConstraint.count
    
    assert_equal @pattern.nodes.first.attribute_constraints.first.attribute_name, "http://example2.org"
    assert_equal @pattern.nodes.first.source_relation_constraints.first.relation_type, "http://example2.org"
  end

end