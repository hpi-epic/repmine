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
    TranslationPattern.any_instance.stub(:correspondences_for_pattern => [])    
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_empty @tp.nodes
    assert_empty @tp.pattern_elements
  end

  it "should create corresponding elements for simple correspondences" do
    # let's translate the first node
    correspondence = FactoryGirl.build(:simple_correspondence)
    
    TranslationPattern.any_instance.stub(:correspondences_for_pattern => [correspondence])
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal 1, @tp.pattern_elements.size
    assert_equal correspondence.entity2, @tp.pattern_elements.first.rdf_type
  end
  
  it "should create corresponding elements for complex correspondences" do
    correspondence = FactoryGirl.build(:complex_correspondence)
    TranslationPattern.any_instance.stub(:correspondences_for_pattern => [correspondence])
    
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)    
    assert_equal correspondence.entity2.pattern_elements.size, @tp.pattern_elements.size
    assert @tp.pattern_elements.all?{|pe| pe.pattern === @tp}
  end
  
  it "should raise an exception if one element could be mapped to two different target structures" do
    correspondence1 = FactoryGirl.build(:simple_correspondence)
    correspondence2 = FactoryGirl.build(:complex_correspondence)
    @pattern.pattern_elements.first.rdf_type = correspondence1.entity1
    om = ontology_matcher(correspondence1, correspondence2)
    assert_equal 2, om.correspondences_for_concept(correspondence1.entity1).size
    expect{TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)}.to raise_error(TranslationPattern::AmbiguousTranslation)
  end
  
  it "should raise an exception if an element is is mapped in multiple mappings" do
    correspondence1 = FactoryGirl.build(:simple_correspondence)
    # this guarantees that a node with type http://example.org/node is matched standalone and as part of the pattern
    correspondence1.entity1 = @pattern.nodes.first.rdf_type
    correspondence2 = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher(correspondence1, correspondence2) 
    expect{TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)}.to raise_error(TranslationPattern::AmbiguousTranslation)
  end

  it "should be able to mix it up... " do
    correspondence1 = FactoryGirl.build(:simple_correspondence)
    correspondence2 = FactoryGirl.build(:hardway_complex)
    om = ontology_matcher(correspondence1, correspondence2)
    new_node = @pattern.create_node!
    new_node.rdf_type = correspondence1.entity1
    tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    # there should be one node comming from the simple correspondence and one from the hardway
    assert_equal 2, tp.pattern_elements.size
  end
  
  def ontology_matcher(c1, c2)
    om = OntologyMatcher.new(@pattern.ontology, @ontology)
    om.alignment_repo.clear!
    om.insert_statements!    
    om.add_correspondence!(c1)
    om.add_correspondence!(c2)
    return om    
  end
end