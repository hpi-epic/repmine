require 'rails_helper'

RSpec.describe OwlClass, :type => :model do
  it "should create valid statements for a class" do
    ont = FactoryGirl.create(:ontology)
    klazz = OwlClass.new(ont, "MyClass", "http://example.org/MyClass")
    klazz.rdf.size.should == 4
  end
  
  it "should be a multiton, if needed" do
    assert OwlClass.find_or_create(nil, "MyClass", "http://example.org/MyClass").eql?(OwlClass.find_or_create(nil, "MyClass", "http://example.org/MyClass"))
    assert !OwlClass.find_or_create(nil, "MyClass", "http://example.org/MyClass2").eql?(OwlClass.find_or_create(nil, "MyClass", "http://example.org/MyClass"))
    assert OwlClass.find_or_create(nil, "MyClass", nil).eql?(OwlClass.find_or_create(nil, "MyClass", nil))
  end
end
