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

  it "should store a complex correspondence if we only provide a list of pattern elements" do
    i_pattern = FactoryGirl.create(:pattern)
    o_pattern = FactoryGirl.create(:pattern)
    cc = ComplexCorrespondence.from_elements(i_pattern.pattern_elements, o_pattern.pattern_elements)
    g = RDF::Graph.new
    g.insert(*cc.rdf_statements)
    g.each do |stmt|
      if stmt[1] == Vocabularies::Alignment.entity1 || stmt[1] == Vocabularies::Alignment.entity2
        assert_not_nil stmt[2]
      end
    end
  end

  it "should also work if we have simple -> complex mappings" do
    i_pattern = FactoryGirl.create(:pattern)
    o_node = FactoryGirl.create(:node_only_pattern).nodes.first
    cc = ComplexCorrespondence.from_elements(i_pattern.pattern_elements, [o_node])
    g = RDF::Graph.new
    g.insert(*cc.rdf_statements)
  end

  it "should determine that we try to fool it ;)" do
    i_node = FactoryGirl.create(:node)
    o_node = FactoryGirl.create(:node)
    cc = ComplexCorrespondence.from_elements([i_node], [o_node])
    assert cc.is_a?(SimpleCorrespondence)
  end
end