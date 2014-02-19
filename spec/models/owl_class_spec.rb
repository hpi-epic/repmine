require 'spec_helper'

describe OwlClass do
  it "should create valid statements for a class" do
    s = Schema.new(build(:repository))
    klazz = OwlClass.new(s, "MyClass")
    klazz.statements.size.should == 4
    # TODO check whether the statements are ok 
  end
end
