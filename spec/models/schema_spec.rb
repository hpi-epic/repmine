require 'spec_helper'

describe Schema do
  it "should create a fancy rdf/xml file for the schema" do
    s = Schema.new(build(:repository))
    owc = OwlClass.new(s, "MyClass")
    puts s.rdf_xml
    
  end
end
