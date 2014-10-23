require 'rails_helper'

RSpec.describe OntologyMatcher, :type => :model do
  
  def alignment_test_file
    Rails.root.join("spec","26_17.rdf").to_s
  end  
  
  before(:each) do
    Ontology.any_instance.stub(:download! => true, :load_to_dedicated_repository! => true)
    Pattern.any_instance.stub(:initialize_repository! => true)
    @pattern = FactoryGirl.create(:pattern)    
    @ontology = FactoryGirl.create(:ontology, :url => "http://example.org/myOntology2")    
    @om = OntologyMatcher.new(@pattern, @ontology)    
  end

  it "should prepare the matching properly" do
    @om.prepare_matching!  
    assert_not_nil @om.source_ont
    assert_equal false, @om.source_ont.new_record?
    assert_not_nil @om.target_ont
    assert_equal true, @om.alignment_path.ends_with?("ont_#{@om.source_ont.id}_ont_#{@om.target_ont.id}.rdf")
  end
  
  it "should equally prepare the matching for combined input ontologies" do
    ontology2 = FactoryGirl.create(:ontology, :url => "http://example.org/myOntology3")    
    @pattern.ontologies << ontology2
    RDF::Graph.any_instance.stub(:load => true)
    @om.prepare_matching!
    assert_not_nil @om.source_ont
    assert_equal true, @om.source_ont.new_record?
    assert_equal true, @om.alignment_path.ends_with?("pattern_#{@om.pattern.id}_ont_#{@om.target_ont.id}.rdf")
  end
  
  it "should not call the matcher when an existing file is present" do
    @om.stub(:alignment_path => alignment_test_file)
    assert_equal true, @om.already_matched?
    expect(@om).to receive(:call_matcher!).never
    expect(@om).to receive(:build_alignment_graph!).once    
    @om.match!
  end
  
  it "should call the matcher when no file is present" do
    Open3.stub(:popen3 => true)
    @om.stub(:alignment_path => Rails.root.join("spec","this_file_should_not_exist.rdf"))
    expect(@om).to receive(:build_alignment_graph!).once
    @om.match!
  end
  
  it "should find substitutes within the rdf files..." do
    @om.stub(:alignment_path => alignment_test_file)
    @om.build_alignment_graph!
    subs = @om.get_substitutes_for("http://crs_dr#author")
    assert_equal 1, subs.size
    assert_equal "http://ekaw#Paper_Author", subs.first[:entity]
    subs = @om.get_substitutes_for("http://crs_dr#author_not_present_in_this_ontology")
    assert_empty subs
  end
end