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

RSpec.describe PatternElement, :type => :model do

  it "should overwrite simple rdf_types" do
    @pe = FactoryGirl.create(:pattern_element)
    assert_equal "http://example.org/generic_element", @pe.rdf_type
    @pe.rdf_type = "http://example.org/MyType2"
    assert_equal "http://example.org/MyType2", @pe.rdf_type
  end

  it "should also overwrite complex ones" do
    @pe = FactoryGirl.create(:pattern_element)
    @pe.type_expression.update_attributes(:operator => OwlClass::SET_OPS[:not])
    assert_equal "#{OwlClass::SET_OPS[:not]}http://example.org/generic_element", @pe.rdf_type
    assert_equal false, @pe.type_expression.is_simple?
    @pe.rdf_type = "http://example.org/MyType2"
    assert_equal "http://example.org/MyType2", @pe.rdf_type
  end

  it "should create a proper element for a given rdf type" do
    @pe = PatternElement.for_rdf_type("http://example.org/fancy_type")
    assert_equal "http://example.org/fancy_type", @pe.rdf_type
  end

  it "should create just what you want it to be" do
    assert Node.for_rdf_type("http://example.org/fancy_type").is_a?(Node)
    assert AttributeConstraint.for_rdf_type("http://example.org/fancy_type").is_a?(AttributeConstraint)
    assert RelationConstraint.for_rdf_type("http://example.org/fancy_type").is_a?(RelationConstraint)
  end
  
  it "should properly detect equality of two generic pattern elements" do
    pe1 = FactoryGirl.create(:pattern_element, :pattern => FactoryGirl.create(:empty_pattern))    
    pe2 = FactoryGirl.create(:pattern_element, :pattern => FactoryGirl.create(:empty_pattern))        
    assert pe1.equal_to?(pe2)
  end
  
  it "should raise an exception when comparing two elements of the same pattern" do
    pattern = FactoryGirl.create(:empty_pattern)
    pe1 = FactoryGirl.create(:pattern_element, :pattern => pattern)    
    pe2 = FactoryGirl.create(:pattern_element, :pattern => pattern)    
    expect{pe1.equal_to?(pe2)}.to raise_error
  end
end
