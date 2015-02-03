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
    @om = OntologyMatcher.new(@pattern.ontology, @ontology)
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
    corrs = @om.correspondences_for_concept("http://ekaw/#Paper_Author", true)
    assert_equal 1, corrs.size
    assert_equal author, corrs.first.entity2
  end
  
  it "should not find non-existing correspondences" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!    
    corrs = @om.correspondences_for_concept("http://crs_dr/#author_not_present_in_this_ontology")
    assert_empty corrs
  end
  
  it "should fix the urls in a broken test file" do
    FileUtils.cp(broken_alignment_test_file_original, broken_alignment_output_file)
    @om.clean_uris!(broken_alignment_output_file)
    g = RDF::Graph.load(broken_alignment_output_file)
    q = RDF::Query.new{
      pattern([:alignment, Vocabularies::Alignment.entity1, :ent1])
      pattern([:alignment, Vocabularies::Alignment.entity2, :ent2])
    }
    g.query(q).each do |res|
      assert_equal true, res[:ent1].to_s.starts_with?("http://crs_dr/")
      assert_equal true, res[:ent2].to_s.starts_with?("http://ekaw/")
    end
  end
  
  it "should properly export a new mapping once we've added that to the alignment graph" do
    correspondence = FactoryGirl.build(:simple_correspondence)
    assert_empty @om.correspondences_for_concept(correspondence.entity1)
    @om.add_correspondence!(correspondence)
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
  
  it "should remove correspondences properly" do
    # create the alignment graph
    FileUtils.cp(alignment_test_file, alignment_test_output_file)
    @om.stub(:alignment_path => alignment_test_output_file)
    @om.match!
    correspondences = @om.correspondences_for_concept("http://crs_dr/#abstract")
    assert_not_empty correspondences
    @om.remove_correspondence!(correspondences.first)
    assert_empty @om.correspondences_for_concept("http://crs_dr/#abstract")
  end
end