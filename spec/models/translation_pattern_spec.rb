require 'rails_helper'

RSpec.describe TranslationPattern, :type => :model do

  before(:each) do
    @pattern = FactoryGirl.create(:pattern)
    @source_ontology = @pattern.ontologies.first
    @target_ontology = FactoryGirl.create(:ontology, :url => "http://example.org/ontology2")
    AgraphConnection.any_instance.stub(:element_class_for_rdf_type => Node)
  end

  it "should create an empty pattern if no correspondences exist" do
    om = ontology_matcher([])
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_empty tp.nodes
    assert_empty tp.pattern_elements
  end

  it "should create corresponding elements for simple correspondences" do
    # let's translate the first node
    correspondence = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence])
    assert @pattern.pattern_elements.none?{|pe| pe.rdf_type == correspondence.entity1}
    @pattern.nodes.first.rdf_type = correspondence.entity1
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!

    assert_equal 1, tp.pattern_elements.size
    assert_equal correspondence.entity2, tp.pattern_elements.first.rdf_type
  end

  it "should create corresponding elements for complex correspondences" do
    correspondence = FactoryGirl.create(:complex_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence])
    assert @pattern.pattern_elements.none?{|pe| pe.rdf_type == correspondence.entity1}
    @pattern.nodes.first.rdf_type = correspondence.entity1
    @tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    @tp.prepare!
    assert @tp.equal_to?(correspondence.entity2)
    # rspec seems to not properly reload has_many relations so we have to do that manually...
    @tp.pattern_elements.reload
    @tp.pattern_elements.none?{|pe| pe.pattern.nil?}
  end

  it "should raise an exception if one element could be mapped to two different target structures" do
    correspondence1 = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    correspondence2 = FactoryGirl.create(:complex_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    @pattern.pattern_elements.first.rdf_type = correspondence1.entity1
    om = ontology_matcher([correspondence1, correspondence2])
    assert_equal 2, om.correspondences_for_concept(correspondence1.entity1).size
    expect{TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology]).prepare!}.to raise_error(TranslationPattern::AmbiguousTranslation)
  end

  it "should determine whether a requested translation already exists and return that instead of a new one" do
    p1 = FactoryGirl.create(:pattern)
    tp1 = TranslationPattern.new(:name => "translation", :description => "just that", :pattern_id => p1.id)
    tp1.ontologies << FactoryGirl.create(:ontology)
    tp1.save

    # simple case - equal ontologies, go for it
    assert_equal tp1, TranslationPattern.for_pattern_and_ontologies(p1, tp1.ontologies)
    # more tricky - the new target is a superset. In that case, the old pattern suffices but should get the new ontology in addition
    o1 = FactoryGirl.create(:ontology)
    tp2 = TranslationPattern.for_pattern_and_ontologies(p1, tp1.ontologies + [o1])
    assert_equal tp1, tp2
    assert_equal tp1.ontologies + [o1], tp2.ontologies
    # finally, we need a new pattern at some point...
    o3 = FactoryGirl.create(:ontology)
    tp3 = TranslationPattern.for_pattern_and_ontologies(p1, [o3])
    assert_not_equal tp3, tp1
  end

  it "should be able to mix it up... " do
    correspondence1 = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    correspondence2 = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence1, correspondence2])
    new_node = @pattern.create_node!(@pattern.ontologies.first)
    new_node.rdf_type = correspondence1.entity1
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    # there should be one node comming from the simple correspondence and one from the hardway
    assert_equal 2, tp.pattern_elements.size
  end

  it "should properly attach elements to the translation pattern" do
    correspondence = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence])
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_equal tp, tp.pattern_elements.first.pattern
  end

  it "should properly set that elements have already been matched" do
    correspondence = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence])
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_equal 3, @pattern.matched_elements([@target_ontology]).size
  end

  it "should be able to adapt a translation pattern if we suddenly know of a new correspondence" do
    correspondence1 = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence1])
    new_node = @pattern.create_node!(@source_ontology)
    new_node.rdf_type = correspondence1.entity1
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!

    assert_equal 1, @pattern.unmatched_elements(@target_ontology).size
    assert_equal new_node, @pattern.unmatched_elements(@target_ontology).first
    assert_equal 1, tp.pattern_elements.size
    assert_equal 1, @pattern.unmatched_elements([@target_ontology]).size

    # adding a new correspondence
    corr2 = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om.add_correspondence!(corr2)
    # now we change the rdf type on one node -> translation is deleted subsequently
    @pattern.unmatched_elements(@target_ontology).first.rdf_type = corr2.entity1
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_empty @pattern.unmatched_elements([@target_ontology])
    assert_equal 2, tp.pattern_elements.size
  end

  it "should throw away existing translation patterns if the original one was changed" do
    correspondence1 = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence1])
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_equal 1, TranslationPattern.count
    @pattern.nodes.first.rdf_type = @pattern.nodes.first.rdf_type + "_new"
    assert_equal 0, TranslationPattern.count
  end

  it "should throw away a translation if an existing element was remvoved" do
    correspondence1 = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence1])
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_equal 1, TranslationPattern.count
    @pattern.nodes.first.destroy
    assert_equal 0, TranslationPattern.count
  end

  it "should extend the translation pattern if the original one was extended" do
    correspondence1 = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence1])

    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    assert_equal 1, TranslationPattern.count
    corr2 = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om.add_correspondence!(corr2)
    new_node = @pattern.create_node!(@source_ontology, corr2.entity1)
    assert_equal 1, TranslationPattern.count
    tp.prepare!
    assert_empty @pattern.unmatched_elements(@target_ontology)
  end

  it "should build a graph if we have simple mappings for node and attribute constraint" do
    c1 = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    c2 = FactoryGirl.create(:simple_attrib_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)

    @pattern = FactoryGirl.create(:empty_pattern)
    om = ontology_matcher([c1, c2])

    node = FactoryGirl.create(:node, :ontology => @source_ontology, :rdf_type => c1.entity1, :pattern => @pattern)
    ac = FactoryGirl.create(:attribute_constraint, :node => node, :rdf_type => c2.entity1, :ontology => @source_ontology)

    AgraphConnection.any_instance.stub(:element_class_for_rdf_type).with(c1.entity2){Node}
    AgraphConnection.any_instance.stub(:element_class_for_rdf_type).with(c2.entity2){AttributeConstraint}

    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!

    assert_equal 2, tp.pattern_elements.size
    assert_equal 1, tp.nodes.size
    assert_equal 1, tp.attribute_constraints.size
    assert_equal tp.attribute_constraints.first.node, tp.nodes.first
  end

  it "should build a graph for simple mappings for node and relation constraints" do
    c1 = FactoryGirl.create(:simple_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)
    c2 = FactoryGirl.create(:simple_relation_correspondence, :onto1 => @source_ontology, :onto2 => @target_ontology)

    @pattern = FactoryGirl.create(:empty_pattern)
    om = ontology_matcher([c1, c2])

    node = FactoryGirl.create(:node, :ontology => @source_ontology, :rdf_type => c1.entity1, :pattern => @pattern)
    node2 = FactoryGirl.create(:node, :ontology => @source_ontology, :rdf_type => c1.entity1, :pattern => @pattern)
    rc = FactoryGirl.create(:relation_constraint, :ontology => @source_ontology, :rdf_type => c2.entity1, :source => node, :target => node2)

    AgraphConnection.any_instance.stub(:element_class_for_rdf_type).with(c2.entity2){RelationConstraint}
    AgraphConnection.any_instance.stub(:element_class_for_rdf_type).with(c1.entity2){Node}

    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!

    assert_equal 3, tp.pattern_elements.size
    assert_equal 2, tp.nodes.size
    assert_equal 1, tp.relation_constraints.size
    assert tp.relation_constraints.first.valid?
    assert_not_equal tp.relation_constraints.first.source, tp.relation_constraints.first.target
  end

  it "should find ambigous mappings based on the found keys" do
    ok = {[1] => [[2]]}
    too_many = {[1] => [[2],[3]]}
    ambiguous = {[1] => [[2]], [1,3] => [[4]]}
    ambiguous_2 = {[1,2] => [[2]], [4,5,1,6,2] => [[4]]}
    TranslationPattern.new.check_for_ambiguous_mappings(ok)
    expect{TranslationPattern.new.check_for_ambiguous_mappings(too_many)}.to raise_error(TranslationPattern::AmbiguousTranslation)
    expect{TranslationPattern.new.check_for_ambiguous_mappings(ambiguous)}.to raise_error(TranslationPattern::AmbiguousTranslation)
    expect{TranslationPattern.new.check_for_ambiguous_mappings(ambiguous_2)}.to raise_error(TranslationPattern::AmbiguousTranslation)
  end

  it "should throw away pattern element matches if an element of a translation pattern changes" do
    correspondence1 = FactoryGirl.create(:hardway_complex, :onto1 => @source_ontology, :onto2 => @target_ontology)
    om = ontology_matcher([correspondence1])
    tp = TranslationPattern.for_pattern_and_ontologies(@pattern, [@target_ontology])
    tp.prepare!
    assert_equal 3, PatternElementMatch.count
    tp.nodes.first.rdf_type = tp.nodes.first.rdf_type + "_new"
    assert_equal 0, PatternElementMatch.count
  end

  def ontology_matcher(correspondences)
    om = OntologyMatcher.new(@source_ontology, @target_ontology)
    om.alignment_repo.clear!
    om.insert_statements!
    correspondences.each{|c| om.add_correspondence!(c)}
    return om
  end
end
