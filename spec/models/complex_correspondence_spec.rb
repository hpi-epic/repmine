require 'rails_helper'

RSpec.describe ComplexCorrespondence, :type => :model do
  
  it "should anonymize entities" do
    ress = []
    3.times{|i| ress << RDF::Resource.new("http://example.org/res#{i}")}
    stmts = [
      [ress[0], ress[1], ress[2]],
      [ress[1], ress[2], ress[0]],
      [ress[2], ress[0], ress[1]],
      [ress[0], ress[0], ress[0]]
    ]
    resource, cleaned_statements = ComplexCorrespondence.clean_rdf_statements(stmts, ress[0])
    assert resource.anonymous?
    cleaned_statements.each{|cs| cs.all?{|el| el.anonymous?}}
    assert_equal resource, cleaned_statements[0][0]
    assert_equal resource, cleaned_statements[1][2]
    assert_equal resource, cleaned_statements[2][1]
    assert cleaned_statements[3].all?{|el| el == resource}
  end
  
  it "should anonymize patterns but leave resources intact" do
    correspondence = FactoryGirl.build(:complex_correspondence)
    ent1, stmts = correspondence.process_entity(correspondence.entity1)
    assert !ent1.anonymous?
    assert_empty stmts
    ent2, stmts = correspondence.process_entity(correspondence.entity2)
    assert ent2.anonymous?
    assert_not_empty stmts
  end
end