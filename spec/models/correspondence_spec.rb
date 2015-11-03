require 'rails_helper'

RSpec.describe Correspondence, :type => :model do

  before(:each) do
    Correspondence.any_instance.stub(:add_to_alignment)
  end

  it "not create duplicate simple correspondences when providing them through different elements" do
    o1 = FactoryGirl.create(:ontology)
    o2 = FactoryGirl.create(:ontology)
    sn1 = FactoryGirl.create(:node, ontology: o1)
    sn2 = FactoryGirl.create(:node, ontology: o1)
    tn1 = FactoryGirl.create(:node, ontology: o2)
    tn2 = FactoryGirl.create(:node, ontology: o2)
    c1 = Correspondence.from_elements([sn1],[tn1])
    c2 = Correspondence.from_elements([sn2],[tn2])
    assert c1.is_a?(SimpleCorrespondence)
    assert_equal c1,c2
    assert_equal 1, Correspondence.count
  end

  it "should not create duplicate complex correspondences when providing them through different elements" do
    o1 = FactoryGirl.create(:ontology)
    o2 = FactoryGirl.create(:ontology)

    sn1 = FactoryGirl.create(:node, ontology: o1)
    ac1 = FactoryGirl.create(:attribute_constraint, ontology: o1, node: sn1)

    sn2 = FactoryGirl.create(:node, ontology: o1)
    ac2 = FactoryGirl.create(:attribute_constraint, ontology: o1, node: sn2)

    tn1 = FactoryGirl.create(:node, ontology: o2)
    tn2 = FactoryGirl.create(:node, ontology: o2)

    c1 = Correspondence.from_elements([sn1, ac1],[tn1])
    c2 = Correspondence.from_elements([sn2, ac2],[tn2])
    assert c1.is_a?(ComplexCorrespondence)
    assert_equal c1,c2
    assert_equal 1, Correspondence.count
  end
end
