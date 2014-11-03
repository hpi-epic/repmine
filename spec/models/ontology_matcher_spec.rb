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
  
  before(:each) do
    Ontology.any_instance.stub(:download! => true, :load_to_dedicated_repository! => true)
    Pattern.any_instance.stub(:initialize_repository! => true)
    @pattern = FactoryGirl.create(:pattern)    
    @ontology = FactoryGirl.create(:ontology, :url => "http://example.org/myOntology2")    
    @om = OntologyMatcher.new(@pattern, [@ontology])
  end
  
  it "should not call the matcher when an existing file is present" do
    @om.stub(:alignment_path => alignment_test_file)
    assert_equal true, @om.already_matched?(@ontology, @ontology)
    expect(@om).to receive(:call_matcher!).never
    expect(@om).to receive(:add_to_alignment_graph!).once    
    @om.match!
  end
  
  it "should call the matcher when no file is present" do
    Open3.stub(:popen3 => true)
    @om.stub(:alignment_path => Rails.root.join("spec","this_file_should_not_exist.rdf"))
    expect(@om.alignment_graph).to receive(:load!).once
    expect(@om).to receive(:clean_uris!).once    
    @om.match!
  end
  
  it "should find substitutes within the rdf files..." do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    subs = @om.get_substitutes_for("http://crs_dr/#author")
    assert_equal 1, subs.size
    assert_equal "http://ekaw/#Paper_Author", subs.first[:entity2]
    subs = @om.get_substitutes_for("http://crs_dr#author_not_present_in_this_ontology")
    assert_empty subs
  end
  
  it "should find substitutes within the rdf files and ignore slight URL deviations" do
    @om.stub(:alignment_path => alignment_test_file)
    @om.match!
    subs = @om.get_substitutes_for("http://crs_dr/#author")
    assert_equal 1, subs.size
    assert_equal "http://ekaw/#Paper_Author", subs.first[:entity2]
    subs = @om.get_substitutes_for("http://crs_dr/#author_not_present_in_this_ontology")
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
  
  it "should survive an rdf import/export cycle" do
    @om.add_to_alignment_graph!(alignment_test_file)
    assert_not_empty @om.get_substitutes_for("http://crs_dr/#author")            
    File.delete(alignment_test_output_file) if File.exists?(alignment_test_output_file)
    @om.write_alignment_graph!(alignment_test_output_file)
    @om.reset!
    @om.add_to_alignment_graph!(alignment_test_output_file)    
    assert_not_empty @om.get_substitutes_for("http://crs_dr/#author")    
  end
  
  it "should properly export a new mapping once we've added that to the alignment graph" do
    # create the alignment graph
    @om.add_to_alignment_graph!(alignment_test_file)
    correspondence = FactoryGirl.build(:ontology_correspondence)
    File.delete(alignment_test_output_file) if File.exists?(alignment_test_output_file)
    @om.add_correspondence_and_write_output!(correspondence, alignment_test_output_file)
    assert_equal true, File.exists?(alignment_test_output_file)
    assert_not_empty @om.get_substitutes_for(correspondence.entity1)
    # here, we check whether a newly created matcher can work with that
    @om.reset!
    @om.add_to_alignment_graph!(alignment_test_output_file)
    assert_not_empty @om.get_substitutes_for(correspondence.entity1)
  end  
  
  it "should properly run for two of the conference ontologies" do
    o1 = Ontology.create(:url => "http://oaei.ontologymatching.org/2014/conference/data/crs_dr.owl", :short_name => "crs")
    o2 = Ontology.create(:url => "http://oaei.ontologymatching.org/2014/conference/data/ekaw.owl", :short_name => "ekaw")
    @pattern.ontologies = [o1]
    @om = OntologyMatcher.new(@pattern, [o2])
    File.delete(aml_test_file) if File.exists?(aml_test_file)
    assert_equal true, @om.alignment_path(o1,o2).ends_with?("ont_#{o1.id}_ont_#{o2.id}.rdf")
    @om.stub(:alignment_path => aml_test_file)    
    @om.match!
    assert_equal true, File.exists?(aml_test_file)
  end
end