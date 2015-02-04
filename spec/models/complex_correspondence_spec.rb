require 'rails_helper'

RSpec.describe ComplexCorrespondence, :type => :model do
  
  it "should anonymize the provided entities" do
    c = FactoryGirl.build(:complex_correspondence)
    assert c.entity2.resource.anonymous?
  end
end