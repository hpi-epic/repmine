require 'rails_helper'

RSpec.describe OntologyMatcher, :type => :model do

  def alignment_test_file
    Rails.root.join("spec", "testfiles","test_alignment.rdf").to_s
  end

  def alignment_test_output_file
    Rails.root.join("spec", "testfiles","test_alignment_output.rdf").to_s
  end

  def broken_alignment_test_file_original
    Rails.root.join("spec", "testfiles","test_alignment_broken_uris.rdf").to_s
  end

  def broken_alignment_output_file
    Rails.root.join("spec", "testfiles","test_alignment_repaired_uris.rdf").to_s
  end

  def aml_test_file
    Rails.root.join("spec", "testfiles","test_me.rdf").to_s
  end

  def author
    "http://crs_dr/#author"
  end

  def not_present
    "http://crs_dr/#author_not_present_in_this_ontology"
  end

  before(:each) do
    @pattern = FactoryGirl.create(:pattern)
    @ontology = FactoryGirl.create(:ontology)
    @om = OntologyMatcher.new(@pattern.ontologies.first, @ontology)
    @om.alignment_repo.clear!
  end

  it "should not call the matcher when an existing file is present" do
    @om.alignment_repo.clear!
    assert_equal false, @om.already_matched?
    dr = RDF::Resource.new("dummy")
    @om.alignment_graph << [dr,dr,dr]
    assert_equal true, @om.already_matched?
    expect(@om).to receive(:call_matcher!).never
    @om.match!
  end

  it "should find substitutes within the rdf files..." do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    corrs = @om.correspondences_for_concept(author)
    assert_equal 1, corrs.size
    assert_equal "http://ekaw/#Paper_Author", corrs.first.entity2
  end

  it "should find substitutes within the rdf files in both directions" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    @om.inverted = true
    corrs = @om.correspondences_for_concept("http://ekaw/#Paper_Author")
    assert_equal 1, corrs.size
    assert_equal author, corrs.first.entity2
  end

  it "should not find non-existing correspondences" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    corrs = @om.correspondences_for_concept("http://crs_dr/#author_not_present_in_this_ontology")
    assert_empty corrs
  end

  it "should switch ontologies, if needed" do
    o1 = FactoryGirl.create(:ontology)
    o2 = FactoryGirl.create(:ontology)
    assert o1.id < o2.id
    assert !OntologyMatcher.new(o1,o2).inverted
    assert OntologyMatcher.new(o2,o1).inverted
  end

  it "should properly insert a new correspondence" do
    correspondence = FactoryGirl.create(:simple_correspondence)
    assert_not_nil @om.find_correspondence_node(correspondence)
    assert_not_empty @om.correspondences_for_concept(correspondence.entity1)
  end

  it "should properly run for two of the conference ontologies" do
    o1 = Ontology.create(:url => "http://oaei.ontologymatching.org/2014/conference/data/crs_dr.owl", :short_name => "crs")
    o1.stub(:local_file_path => Rails.root.join("spec", "testfiles","crs_dr.owl").to_s)
    o2 = Ontology.create(:url => "http://oaei.ontologymatching.org/2014/conference/data/ekaw.owl", :short_name => "ekaw")
    o2.stub(:local_file_path => Rails.root.join("spec", "testfiles","ekaw.owl").to_s)
    @om = OntologyMatcher.new(o1, o2)
    File.delete(aml_test_file) if File.exists?(aml_test_file)
    @om.stub(:alignment_path => aml_test_file)
    assert !@om.already_matched?
    @om.match!
    assert_equal true, File.exists?(aml_test_file)
  end

  it "should find an existing correspondence within the graph" do
    correspondence = FactoryGirl.create(:simple_correspondence)
    assert_not_empty @om.alignment_graph
    assert_not_nil @om.find_correspondence_node(correspondence)
  end

  it "should remove an existing correspondence from the graph" do
    correspondence = FactoryGirl.create(:simple_correspondence)
    assert_not_empty @om.alignment_graph
    rdf_node = @om.remove_correspondence!(correspondence)
    assert_empty @om.alignment_graph
  end

  it "should remove correspondences properly" do
    FileUtils.cp(alignment_test_file, alignment_test_output_file)
    @om.stub(:alignment_path => alignment_test_output_file)
    @om.match!
    correspondences = @om.correspondences_for_concept("http://crs_dr/#abstract")
    assert_equal 1, correspondences.size
    assert_not_nil @om.find_correspondence_node(correspondences.first)
    @om.remove_correspondence!(correspondences.first)
    assert_empty @om.correspondences_for_concept("http://crs_dr/#abstract")
  end

  it "should remove complex correspondences properly from the alignment graph" do
    c1 = FactoryGirl.create(:complex_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    correspondences = @om.correspondences_for_concept(c1.entity1)
    assert_equal 1, correspondences.size
    @om.remove_correspondence!(c1)
    assert_empty @om.alignment_graph
  end

  it "should only remove the desired one of similar correspondences" do
    c1 = FactoryGirl.create(:complex_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    c2 = FactoryGirl.create(:complex_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    assert_equal 2, @om.correspondences_for_concept(c1.entity1).size
    @om.remove_correspondence!(c1)
    assert_not_empty @om.alignment_graph
    assert_equal 1, @om.correspondences_for_concept(c1.entity1).size
  end

  it "should remove simple correspondences properly from the alignment graph" do
    c1 = FactoryGirl.create(:simple_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    correspondences = @om.correspondences_for_concept(c1.entity1)
    assert_equal 1, correspondences.size
    @om.remove_correspondence!(c1)
    assert_empty @om.alignment_graph
  end

  it "should properly add a complex correspondence" do
    correspondence = FactoryGirl.create(:complex_correspondence)
    assert_not_empty @om.alignment_graph
    corrs = @om.correspondences_for_concept(correspondence.entity1)
    assert_not_empty corrs
    assert_equal ComplexCorrespondence, corrs.first.class
  end

  it "should add a complex correspondence stemming from just sample elements and find it again" do
    p1 = FactoryGirl.create(:pattern)
    p2 = FactoryGirl.create(:pattern)
    cc = ComplexCorrespondence.from_elements(p1.pattern_elements, p2.pattern_elements)
    @om.insert_statements!
    corrs = @om.correspondences_for_pattern_elements(p1.pattern_elements)
    assert_not_empty corrs
    assert_equal p2.pattern_elements.size, corrs.first.pattern_elements.size
  end

  it "should find a complex correspondence based on provided elements" do
    correspondence = FactoryGirl.create(:hardway_complex)
    pattern = FactoryGirl.create(:pattern)
    @om.insert_statements!
    @om.print_alignment_graph!
    corrs = @om.correspondences_for_pattern_elements(pattern.pattern_elements)
    assert_not_empty corrs
    assert_equal ComplexCorrespondence, corrs.first.class
  end

  it "should not return correspondences where the input graph only matches a real subgraph of entity1" do
    correspondence = FactoryGirl.create(:hardway_complex)
    @om.insert_statements!
    pattern = FactoryGirl.create(:pattern)
    corrs = @om.correspondences_for_pattern_elements(pattern.pattern_elements[0..-2])
    assert_empty corrs
  end

  it "should be able to build complex correspondences" do
    correspondence = FactoryGirl.create(:complex_correspondence)
    @om.insert_statements!
    corr = @om.correspondences_for_concept(correspondence.entity1).first
    assert_not_nil corr
    assert corr.is_a?(ComplexCorrespondence)
    assert corr.entity2.is_a?(Pattern)
    assert_equal correspondence.entity2.pattern_elements.size, corr.entity2.pattern_elements.size

    correspondence.entity2.pattern_elements.each do |pe|
      assert corr.entity2.pattern_elements.any?{|pee| pe.equal_to?(pee)}, "no match found for #{pe.class} - #{pe.rdf_type}"
    end
  end

  it "should create a new correspondence for an unnamed one created by the automated matcher" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    assert_equal 1, Correspondence.count
  end
end