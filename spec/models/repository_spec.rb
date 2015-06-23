require 'rails_helper'

RSpec.describe Repository, :type => :model do

  it "should return a new instance for known types" do
    assert_not_nil Repository.for_type("RdfRepository")
  end

  it "should return nil for unknown types" do
    assert_nil Repository.for_type("ThisIsNotARepositoryType")
  end

end
