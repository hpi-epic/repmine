require 'rails_helper'

RSpec.describe OntologyCorrespondence, :type => :model do
  
  def alignment_test_file
    Rails.root.join("spec", "testfiles","test_alignment.rdf").to_s
  end
  
  def alignment_test_output_file
    Rails.root.join("spec", "testfiles","test_alignment_output.rdf").to_s    
  end
  
  it "should create a new correspondence" do
    OntologyMatcher.any_instance.stub(:alignment_path => alignment_test_output_file)    
    Pattern.any_instance.stub(:initialize_repository! => true)
    alignment_graph = RDF::Graph.new
    alignment_graph.load!(alignment_test_file)
    OntologyMatcher.any_instance.stub(:alignment_graph => alignment_graph)        
    
    @pattern = FactoryGirl.create(:pattern)
    @pattern2 = FactoryGirl.create(:node_only_pattern)
    input_elements = [@pattern.nodes.first]
    output_elements = [@pattern2.nodes.first]
    oc = OntologyCorrespondence.for_elements!(input_elements, output_elements, @pattern, @pattern.ontologies.first, @pattern2.ontologies.first)
    OntologyMatcher.any_instance.unstub(:alignment_graph)
    om = OntologyMatcher.new(@pattern, @pattern2.ontologies.first)
    subs = om.get_substitutes_for([@pattern.nodes.first])
    assert_equal 1, subs.size
    assert_equal subs.first, oc
  end
  
end