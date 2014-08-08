require 'rails_helper'

RSpec.describe OwlClass, :type => :model do  
  it "should create valid statements for a class" do
    s = FactoryGirl.create(:repository).ontology
    klazz = OwlClass.new(s, "MyClass")
    klazz.statements.size.should == 4
    # TODO check whether the statements are ok 
  end
end