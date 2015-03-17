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
  end

  it "should create an empty pattern if no correspondences exist" do
    OntologyMatcher.any_instance.stub(:correspondences_for_pattern => [])    
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_empty @tp.nodes
    assert_empty @tp.pattern_elements
  end

  it "should create corresponding elements for simple correspondences" do
    # let's translate the first node
    correspondence = FactoryGirl.build(:simple_correspondence)
    OntologyMatcher.any_instance.stub(:correspondences_for_pattern => [correspondence])
    AgraphConnection.any_instance.stub(:element_class_for_rdf_type => Node)
    @tp = TranslationPattern.for_pattern_and_ontology(@pattern, @ontology)
    assert_equal 1, @tp.pattern_elements.size
    assert_equal correspondence.entity2, @tp.pattern_elements.first.rdf_type
  end

end
