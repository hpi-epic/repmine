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

  it "should find substitutes within the rdf files in both directions" do
    o1 = FactoryGirl.create(:ontology, url: "http://ekaw/")
    o2 = FactoryGirl.create(:ontology, url: "http://crs_dr/")
    om = OntologyMatcher.new(o2,o1)
    fn = "ont_#{o1.id}_ont_#{o2.id}.rdf"
    assert_equal Rails.root.join("public", "ontologies", "alignments", fn).to_s, om.alignment_path
    om.stub(:alignment_path => alignment_test_file)
    om.match!

    node = FactoryGirl.create(:node, rdf_type: "http://ekaw/#Paper_Author")
    corrs = om.correspondences_for([node])
    assert_equal 1, corrs.size
    assert_equal author, corrs[[node]].first.pattern_elements.first.rdf_type
  end

  it "should switch ontologies, if needed" do
    o1 = FactoryGirl.create(:ontology)
    o2 = FactoryGirl.create(:ontology)
    assert o1.id < o2.id
    assert !OntologyMatcher.new(o1,o2).inverted
    assert OntologyMatcher.new(o2,o1).inverted
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
    assert @om.has_correspondence_node?(correspondence)
  end

  it "should remove an existing correspondence from the graph" do
    correspondence = FactoryGirl.create(:simple_correspondence)
    assert_not_empty @om.alignment_graph
    rdf_node = @om.remove_correspondence!(correspondence)
    assert_empty @om.alignment_graph
  end

  it "should remove complex correspondences properly from the alignment graph" do
    c1 = FactoryGirl.create(:complex_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    assert_not_empty @om.alignment_graph
    @om.remove_correspondence!(c1)
    assert_empty @om.alignment_graph
  end

  it "should only remove the desired one of similar correspondences" do
    c1 = FactoryGirl.create(:complex_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    c2 = FactoryGirl.create(:complex_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    @om.remove_correspondence!(c1)
    assert_not_empty @om.alignment_graph
  end

  it "should remove simple correspondences properly from the alignment graph" do
    c1 = FactoryGirl.create(:simple_correspondence, :onto1 => @om.source_ontology, :onto2 => @om.target_ontology)
    assert_not_empty @om.alignment_graph
    @om.remove_correspondence!(c1)
    assert_empty @om.alignment_graph
  end

  it "should be able to build complex correspondences" do
    correspondence = FactoryGirl.create(:complex_correspondence)
    @om.insert_graph_pattern_ontology!
    corr = Correspondence.find(correspondence.id)
    assert_equal correspondence.entity2.size, corr.pattern_elements.size

    correspondence.entity2.each do |pe|
      assert corr.pattern_elements.any?{|pee| pe.equal_to?(pee)}, "no match found for #{pe.class} - #{pe.rdf_type}"
    end
  end

  it "should create a new correspondence for an unnamed one created by the automated matcher" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    assert_equal 8, Correspondence.count
  end
end