require 'rails_helper'

RSpec.describe SimpleCorrespondence, :type => :model do
  it "should properly provide query patterns" do
    c = FactoryGirl.build(:simple_correspondence)
    c.query_patterns.each do |qp|
      assert qp.is_a?(RDF::Query::Pattern)      
      assert_not_nil qp.variables[:cell]
    end
  end
end
