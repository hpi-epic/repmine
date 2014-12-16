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
  end
  
  it "should not call the matcher when an existing file is present" do
    @om.stub(:alignment_path => alignment_test_file)
    assert_equal true, @om.already_matched?    
    expect(@om).to receive(:call_matcher!).never
    expect(@om).to receive(:add_to_alignment_graph!).once
    @om.match!
  end
  
  it "should not call the matcher if we have a matching in the other direction" do
    assert_not_equal @om.source_ontology, @om.target_ontology
    File.stub(:exist?).with(@om.alignment_path){true}
    @om2 = OntologyMatcher.new(@om.target_ontology, @om.source_ontology)
    File.stub(:exist?).with(@om2.alignment_path){false}
    assert_equal true, @om2.already_matched?
  end
  
  it "should call the matcher when no file is present" do
    Open3.stub(:popen3 => true)
    @om.stub(:alignment_path => Rails.root.join("spec","this_file_should_not_exist.rdf"))
    assert !@om.already_matched?
    expect(@om).to receive(:clean_uris!).once  
    @om.match!
  end
  
  it "should find substitutes within the rdf files..." do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    subs = @om.get_substitutes_for([PatternElement.for_rdf_type(author)])
    assert_equal 1, subs.size
    assert_equal "http://ekaw/#Paper_Author", subs.first.entity2.rdf_type
    subs = @om.get_substitutes_for([PatternElement.for_rdf_type("http://crs_dr/#author_not_present_in_this_ontology")])
    assert_empty subs
  end
  
  it "should find substitutes within the rdf files and ignore slight URL deviations" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    subs = @om.get_substitutes_for([PatternElement.for_rdf_type(author)])
    assert_equal 1, subs.size
    assert_equal "http://ekaw/#Paper_Author", subs.first.entity2.rdf_type
    subs = @om.get_substitutes_for([PatternElement.for_rdf_type(not_present)])
    assert_empty subs
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
  
  it "should provide correspondences only for the matched elements" do
    @om.add_to_alignment_graph!(alignment_test_file)
    pe1 = PatternElement.for_rdf_type(author)
    pe2 = PatternElement.for_rdf_type(not_present)
    subs = @om.get_substitutes_for([pe1, pe2])
    assert_equal 1, subs.size
    assert_equal 1, subs.first.input_elements.size
    assert_not_include subs.first.input_elements, pe2
  end
  
  it "should return matched elements of the proper type" do
    @om.add_to_alignment_graph!(alignment_test_file)
    pe1 = PatternElement.for_rdf_type(author)
    Ontology.any_instance.stub(:element_class_for_rdf_type => AttributeConstraint)
    subs = @om.get_substitutes_for([pe1])
    assert subs.first.output_elements.first.is_a?(AttributeConstraint)
  end
  
  it "should survive an rdf import/export cycle" do
    @om.add_to_alignment_graph!(alignment_test_file)
    assert_not_empty @om.get_substitutes_for([PatternElement.for_rdf_type(author)])            
    File.delete(alignment_test_output_file) if File.exists?(alignment_test_output_file)
    @om.write_alignment_graph!(alignment_test_output_file)
    @om.reset!
    @om.add_to_alignment_graph!(alignment_test_output_file)    
    assert_not_empty @om.get_substitutes_for([PatternElement.for_rdf_type(author)])
  end
  
  it "should properly export a new mapping once we've added that to the alignment graph" do
    # create the alignment graph
    @om.add_to_alignment_graph!(alignment_test_file)
    correspondence = FactoryGirl.create(:ontology_correspondence)
    File.delete(alignment_test_output_file) if File.exists?(alignment_test_output_file)
    @om.stub(:alignment_path => alignment_test_output_file)
    @om.add_correspondence!(correspondence)
    assert_equal true, File.exists?(alignment_test_output_file)
    assert_not_empty @om.get_substitutes_for(correspondence.input_elements)
    # here, we check whether a newly created matcher can work with that
    @om.reset!
    @om.add_to_alignment_graph!(alignment_test_output_file)
    assert_not_empty @om.get_substitutes_for(correspondence.input_elements)
  end  
  
  it "should properly run for two of the conference ontologies" do
    o1 = Ontology.create(:url => "http://oaei.ontologymatching.org/2014/conference/data/crs_dr.owl", :short_name => "crs")
    o1.stub(:local_file_path => Rails.root.join("spec", "testfiles","crs_dr.owl").to_s)
    o2 = Ontology.create(:url => "http://oaei.ontologymatching.org/2014/conference/data/ekaw.owl", :short_name => "ekaw")
    o2.stub(:local_file_path => Rails.root.join("spec", "testfiles","ekaw.owl").to_s)
    @om = OntologyMatcher.new(o1, o2)
    File.delete(aml_test_file) if File.exists?(aml_test_file)
    assert_equal true, @om.alignment_path.ends_with?("ont_#{o1.id}_ont_#{o2.id}.rdf")
    @om.stub(:alignment_path => aml_test_file)
    assert !@om.already_matched?
    @om.match!
    assert_equal true, File.exists?(aml_test_file)
  end
  
  it "should not return a new correspondence if we already have one" do
    @om.add_to_alignment_graph!(alignment_test_file)
    pe1 = PatternElement.for_rdf_type(author)
    pe2 = PatternElement.for_rdf_type(not_present)
    oc = OntologyCorrespondence.create(:input_ontology => @ontology, :output_ontology => @ontology, :measure => 1.0, :relation => "=")
    oc.input_elements << pe1
    oc.output_elements << pe2
    count_before = OntologyCorrespondence.count
    subs = @om.get_substitutes_for([pe1])
    assert_equal 1, subs.size
    assert_equal oc, subs.first
    assert_equal count_before, OntologyCorrespondence.count
  end
end