require 'rails_helper'

RSpec.describe Measurable, :type => :model do

  it "should group stuff in the desired manner" do
    m1 = FactoryGirl.create(:pattern)
    m1.tag_list.add("awesome", "cool", "manly")
    m1.save
    m2 = FactoryGirl.create(:pattern)
    m2.tag_list.add("awesome", "cool", "womanly")
    m2.save
    m3 = FactoryGirl.create(:pattern)
    group = Measurable.grouped()
    expect(group).to be_empty
    group = Pattern.grouped()
    expect(group.size).to eq(5)
    expect(group.keys.to_set).to eq(["Uncategorized", "awesome", "cool", "manly", "womanly"].to_set)
    expect(group["Uncategorized"]).to eq([m3])
    expect(Pattern.grouped([m3.id])["Uncategorized"]).to be_nil
  end
end
