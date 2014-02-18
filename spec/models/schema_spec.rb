require 'spec_helper'

describe Schema do
  it "should create a fancy rdf/xml file for the schema" do
    s = Schema.new("http://example.org/ontologies/extracted/", "my_schema")
    owc = OwlClass.new(s, "MyClass")
    puts s.rdf_xml
  end
end
