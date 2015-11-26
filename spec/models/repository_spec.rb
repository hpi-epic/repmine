require 'rails_helper'

RSpec.describe Repository, :type => :model do

  it "should return a new instance for known types" do
    assert_not_nil Repository.for_type(Repository::TYPES.keys.first)
  end

  it "should return nil for unknown types" do
    wrong = Repository::TYPES.keys.first + "NOT!"
    expect{Repository.for_type(wrong)}.to raise_error(Regexp.new(wrong))
  end

end
