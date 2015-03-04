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
  
  it "should switch ontologies, if needed" do
    o1 = FactoryGirl.create(:ontology)
    o2 = FactoryGirl.create(:ontology)
    assert o1.id < o2.id
    assert !OntologyMatcher.new(o1,o2).inverted
    assert OntologyMatcher.new(o2,o1).inverted
  end
  
  it "should properly insert a new correspondence" do
    correspondence = FactoryGirl.build(:simple_correspondence)
    assert_empty @om.correspondences_for_concept(correspondence.entity1)
    @om.add_correspondence!(correspondence)
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
    correspondence = FactoryGirl.build(:simple_correspondence)
    assert_empty @om.alignment_graph
    @om.add_correspondence!(correspondence)
    assert_not_empty @om.alignment_graph
    assert_not_nil @om.find_correspondence_node(correspondence)
  end
  
  it "should remove an existing correspondence from the graph" do
    correspondence = FactoryGirl.build(:simple_correspondence)
    assert_empty @om.alignment_graph
    @om.add_correspondence!(correspondence)
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
  
  it "should properly add a complex correspondence" do
    correspondence = FactoryGirl.build(:complex_correspondence)
    assert_empty @om.alignment_graph
    assert_empty @om.correspondences_for_concept(correspondence.entity1)
    @om.add_correspondence!(correspondence)
    assert_not_empty @om.alignment_graph
    corrs = @om.correspondences_for_concept(correspondence.entity1)    
    assert_not_empty corrs
  end
  
  it "should be able to build complex correspondences" do
    correspondence = FactoryGirl.build(:complex_correspondence)
    @om.insert_statements!
    @om.add_correspondence!(correspondence)
    corr = @om.correspondences_for_concept(correspondence.entity1).first
    assert_not_nil corr
    assert corr.is_a?(ComplexCorrespondence)
    assert corr.entity2.is_a?(Pattern)
    assert_equal correspondence.entity2.pattern_elements.size, corr.entity2.pattern_elements.size
    
    correspondence.entity2.pattern_elements.each do |pe|
      assert corr.entity2.pattern_elements.any?{|pee| pee.equal_to?(pe)}, "no match found for #{pe.class.name} #{pe.rdf_type}"
    end
  end
end