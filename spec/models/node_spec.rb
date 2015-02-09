# == Schema Information
#
# Table name: pattern_elements
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pattern_id      :integer
#  node_id         :integer
#  value           :string(255)
#  operator        :string(255)
#  min_cardinality :string(255)
#  max_cardinality :string(255)
#  min_path_length :string(255)
#  max_path_length :string(255)
#  source_id       :integer
#  target_id       :integer
#  x               :integer          default(0)
#  y               :integer          default(0)
#  is_group        :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe Node, :type => :model do
  it "should figure out two simple nodes are equal" do
    n1 = FactoryGirl.create(:plain_node, :pattern => FactoryGirl.create(:empty_pattern))
    n2 = FactoryGirl.create(:plain_node, :pattern => FactoryGirl.create(:empty_pattern))    
    assert n1.equal_to?(n2)
  end
  
  it "should figure out the difference between a simple node and one with outgoing relations" do
    n1 = FactoryGirl.create(:pattern).nodes.first
    n2 = FactoryGirl.create(:pattern).nodes.first
    n2.source_relation_constraints.first.destroy
    assert !n1.equal_to?(n2)
  end
  
  it "should check too many relations" do
    p1 = FactoryGirl.create(:pattern)
    n1 = p1.nodes.first    
    n2 = FactoryGirl.create(:pattern).nodes.first
    rc = RelationConstraint.create(:source_id => p1.nodes.last.id, :target_id => n1.id)
    assert !n1.equal_to?(n2)
  end
  
  it "should tell the difference between incoming and outgoing" do
    n1 = FactoryGirl.create(:pattern).nodes.first
    n2 = FactoryGirl.create(:pattern).nodes.last
    n3 = n1.pattern.create_node!
    rc = RelationConstraint.create(:source_id => n3.id, :target_id => n1.id)
    assert !n1.equal_to?(n2)
  end
  
  it "should figure out an additional attribute constraint" do
    n1 = FactoryGirl.create(:pattern).nodes.first
    n2 = FactoryGirl.create(:pattern).nodes.first
    ac = FactoryGirl.create(:attribute_constraint, :node => n1)
    assert !n1.equal_to?(n2)
  end
  
  it "should figure out differing attribute constraints" do
    n1 = FactoryGirl.create(:pattern).nodes.first
    n2 = FactoryGirl.create(:pattern).nodes.first
    n2.attribute_constraints.first.rdf_type = n1.attribute_constraints.first.rdf_type + "stuff"
    assert !n1.equal_to?(n2)
  end
  
  it "should figure out that strange case..." do
    n1 = FactoryGirl.create(:pattern).nodes.first
    n2 = FactoryGirl.create(:pattern).nodes.first
    ac1 = FactoryGirl.create(:attribute_constraint, :node => n1)
    ac2 = FactoryGirl.create(:attribute_constraint, :node => n2)
    ac2.rdf_type = ac1.rdf_type + "stuff"
    assert !n1.equal_to?(n2)
  end  
end
