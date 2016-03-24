require 'rails_helper'

RSpec.describe QueryCreator, :type => :model do

  it "should provide nicely underscored variable names" do
    pe = FactoryGirl.create(:node)
    pe.name = "This should have underscores"
    qc = QueryCreator.new(pe.pattern, [])
    expect(qc.pe_variable(pe)).to eq(:this_should_have_underscores)
  end

  it "should raise an error if we did not implement build query" do
    pe = FactoryGirl.create(:node)
    qc = QueryCreator.new(pe.pattern, [])
    expect{qc.query_string}.to raise_error(Regexp.new("implement"))
  end

end