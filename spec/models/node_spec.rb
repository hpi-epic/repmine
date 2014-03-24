require 'spec_helper'

describe Node do
  it "should create a valid relation constraint between itself and a target node" do
    source = create(:node)
    target = create(:node)
    rel_constraint = source.create_constraint_with_target!(target)
    rel_constraint.source.should == source
    rel_constraint.target.should == target
  end
end
