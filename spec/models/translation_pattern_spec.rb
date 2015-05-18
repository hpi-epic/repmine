# == Schema Information
#
# Table name: patterns
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  ontology_id :integer
#  type        :string(255)
#  pattern_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe TranslationPattern, :type => :model do

  before(:each) do
    @pattern = FactoryGirl.create(:pattern)
    @ontology = FactoryGirl.create(:ontology, :url => "http://example.org/ontology2")
    AgraphConnection.any_instance.stub(:element_class_for_rdf_type => Node)    
  end

  it "should create an empty pattern if no correspondences exist" do
    om = ontology_matcher([])    
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_empty @tp.nodes
    assert_empty @tp.pattern_elements
  end

  it "should create corresponding elements for simple correspondences" do
    # let's translate the first node
    correspondence = FactoryGirl.build(:simple_correspondence)
    om = ontology_matcher([correspondence])
    assert @pattern.pattern_elements.none?{|pe| pe.rdf_type == correspondence.entity1}
    @pattern.nodes.first.rdf_type = correspondence.entity1
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal 1, @tp.pattern_elements.size    
    assert_equal correspondence.entity2, @tp.pattern_elements.first.rdf_type
  end
  
  it "should create corresponding elements for complex correspondences" do
    correspondence = FactoryGirl.build(:complex_correspondence)
    om = ontology_matcher([correspondence])
    assert @pattern.pattern_elements.none?{|pe| pe.rdf_type == correspondence.entity1}    
    @pattern.nodes.first.rdf_type = correspondence.entity1
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert @tp.equal_to?(correspondence.entity2)
    # rspec seems to not properly reload has_many relations so we have to do that manually...
    @tp.pattern_elements.reload
    @tp.pattern_elements.none?{|pe| pe.pattern.nil?}
  end
  
  it "should raise an exception if one element could be mapped to two different target structures" do
    correspondence1 = FactoryGirl.build(:simple_correspondence)
    correspondence2 = FactoryGirl.build(:complex_correspondence)
    @pattern.pattern_elements.first.rdf_type = correspondence1.entity1
    om = ontology_matcher([correspondence1, correspondence2])
    assert_equal 2, om.correspondences_for_concept(correspondence1.entity1).size
    expect{TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)}.to raise_error(TranslationPattern::AmbiguousTranslation)
  end
  
  it "should give simple correspondences precedence over complex ones" do
    correspondence1 = FactoryGirl.build(:simple_correspondence)
    # this guarantees that a node with type http://example.org/node is matched standalone and as part of the pattern
    correspondence1.entity1 = @pattern.nodes.first.rdf_type
    matchable_nodes = @pattern.pattern_elements.select{|pe| pe.rdf_type == correspondence1.entity1}
    correspondence2 = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher([correspondence1, correspondence2])
    tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    
    assert_equal matchable_nodes.size, tp.nodes.size
    assert_equal matchable_nodes, @pattern.matched_elements(@ontology)
  end

  it "should be able to mix it up... " do
    correspondence1 = FactoryGirl.build(:simple_correspondence)
    correspondence2 = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher([correspondence1, correspondence2])
    new_node = @pattern.create_node!
    new_node.rdf_type = correspondence1.entity1
    tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    # there should be one node comming from the simple correspondence and one from the hardway
    assert_equal 2, tp.pattern_elements.size
  end
  
  it "should properly attach elements to the translation pattern" do
    correspondence = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher([correspondence])
    tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal tp, tp.pattern_elements.first.pattern
  end
  
  it "should properly set that elements have already been matched" do
    correspondence = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher([correspondence])
    new_node = @pattern.create_node!
    tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal 1, tp.pattern_elements.size
    assert_equal 3, @pattern.matched_elements(@ontology).size
  end
  
  it "should be able to adapt a translation pattern if we suddenly know of a new correspondence" do
    correspondence1 = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher([correspondence1])
    new_node = @pattern.create_node!
    new_node.rdf_type = correspondence1.entity1
    tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal new_node, @pattern.unmatched_elements(@ontology).first
    assert_equal 1, tp.pattern_elements.size
    assert_equal 1, @pattern.unmatched_elements(@ontology).size
    corr2 = FactoryGirl.build(:simple_correspondence)
    om.add_correspondence!(corr2)
    @pattern.unmatched_elements(@ontology).first.rdf_type = corr2.entity1
    tp.prepare!()
    assert_empty @pattern.unmatched_elements(@ontology)
    assert_equal 2, tp.pattern_elements.size
  end
  
  def ontology_matcher(correspondences)
    om = OntologyMatcher.new(@pattern.ontology, @ontology)
    om.alignment_repo.clear!
    om.insert_statements!
    correspondences.each{|c| om.add_correspondence!(c)}
    return om    
  end
end