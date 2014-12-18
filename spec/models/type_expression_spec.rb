require 'rails_helper'

RSpec.describe TypeExpression, :type => :model do

  before :all do
    @sup = OwlClass::SET_OPS[:sup]
    @sub = OwlClass::SET_OPS[:sub]
    @not = OwlClass::SET_OPS[:not]
    @ttype = "http://example.org/MyType"
  end

  it "should create the correct string representation for a simple type expression" do
    te = TypeExpression.for_rdf_type(nil, @ttype)
    te.fancy_string.should == @ttype
    te.fancy_string(true).should == "MyType"
  end

  it "should create fancy strings for negations" do
    nott = TypeExpression.for_rdf_type_and_operator(nil, @ttype, @not)
    nott.fancy_string.should == "#{@not}#{@ttype}"
  end

  it "should create string for n-ary (n >= 2) operators" do
    sup = FactoryGirl.create(:type_expression_sup)
    te1 = FactoryGirl.create(:type_expression_plain, :parent => sup)
    te2 = FactoryGirl.create(:type_expression_plain, :parent => sup)
    te3 = FactoryGirl.create(:type_expression_plain, :parent => sup)
    sup.fancy_string.should == [te1,te2,te3].collect{|te| te.rdf_type}.join(@sup)
  end

  it "should create nested expression with binary + unary ops" do
    sup = FactoryGirl.create(:type_expression_sup)
    te1 = FactoryGirl.create(:type_expression_plain, :parent => sup)
    nott = FactoryGirl.create(:type_expression_not, :parent => sup)
    te2 = FactoryGirl.create(:type_expression_plain, :parent => nott)
    sup.fancy_string.should == "#{te1.rdf_type}#{@sup}#{@not}#{te2.rdf_type}"
  end

  it "should put brackets around everything lower than level 1" do
    sup = FactoryGirl.create(:type_expression_sup)
    te1 = FactoryGirl.create(:type_expression_plain, :parent => sup)
    sub = FactoryGirl.create(:type_expression_sub, :parent => sup)
    te2 = FactoryGirl.create(:type_expression_2, :parent => sub)
    te3 = FactoryGirl.create(:type_expression_3, :parent => sub)
    sup.fancy_string.should == "#{te1.rdf_type}#{@sup}(#{te2.rdf_type}#{@sub}#{te3.rdf_type})"
  end

  it "should negate binary ops" do
    nott = FactoryGirl.create(:type_expression_not)
    sub = FactoryGirl.create(:type_expression_sub, :parent => nott)
    te1 = FactoryGirl.create(:type_expression_plain, :parent => sub)
    te2 = FactoryGirl.create(:type_expression_2, :parent => sub)
    nott.fancy_string.should == "#{@not}(#{te1.rdf_type}#{@sub}#{te2.rdf_type})"
  end

  it "should create a proper structure for operators" do
    nott = TypeExpression.for_operator(nil, @not)
    assert_equal "#{@not}()", nott.fancy_string
  end

end
