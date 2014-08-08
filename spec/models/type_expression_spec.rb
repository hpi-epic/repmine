require 'rails_helper'

RSpec.describe TypeExpression, :type => :model do
  it "should create the correct string representation for a simple type expression" do
    @simple_te = FactoryGirl.build(:type_expression)
    @simple_te.fancy_string.should == "http://example.org/MyType"
    @simple_te.fancy_string(true).should == "MyType"
  end
  
  it "should create fancy strings for negations" do
    @not = FactoryGirl.create(:type_expression_not)
    te = FactoryGirl.create(:type_expression, :parent => @not)
    @not.fancy_string.should == "#{OwlClass::SET_OPS[:not]}#{te.rdf_type}"
  end
  
  it "should create string for n-ary (n >= 2) operators" do
    @sup = FactoryGirl.create(:type_expression_sup)
    te1 = FactoryGirl.create(:type_expression, :parent => @sup)
    te2 = FactoryGirl.create(:type_expression, :parent => @sup)  
    te3 = FactoryGirl.create(:type_expression, :parent => @sup)
    @sup.fancy_string.should == [te1,te2,te3].collect{|te| te.rdf_type}.join(OwlClass::SET_OPS[:sup])
  end
  
  it "should create nested expression with binary + unary ops" do
    @sup = FactoryGirl.create(:type_expression_sup)
    te1 = FactoryGirl.create(:type_expression, :parent => @sup)
    nott = FactoryGirl.create(:type_expression_not, :parent => @sup)
    te2 = FactoryGirl.create(:type_expression, :parent => nott)
    @sup.fancy_string.should == "#{te1.rdf_type}#{OwlClass::SET_OPS[:sup]}#{OwlClass::SET_OPS[:not]}#{te2.rdf_type}"
  end
end
