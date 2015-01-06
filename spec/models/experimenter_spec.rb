require 'rails_helper'

RSpec.describe Experimenter, :type => :model do
  
  def small_ontology
    Ontology.where(:url => "http://oaei.ontologymatching.org/2014/conference/data/ekaw.owl").first_or_create
  end
  
  def large_ontology
    Ontology.where(:url => "http://oaei.ontologymatching.org/2014/conference/data/Conference.owl").first_or_create
  end
  
  before(:each) do 
    Ontology.any_instance.unstub(:download!)
    Ontology.any_instance.unstub(:load_to_dedicated_repository!)
    Ontology.any_instance.unstub(:delete_repository!)
    Ontology.any_instance.unstub(:element_class_for_rdf_type)
  end
  
  after(:each) do
    small_ontology.delete_repository!
    large_ontology.delete_repository!
  end
  
  it "should properly determine which one is the smaller model" do
    e = Experimenter.new(small_ontology, large_ontology)
    assert_equal e.smaller_ontology, small_ontology
    assert_equal e.bigger_ontology, large_ontology
    e = Experimenter.new(large_ontology, small_ontology)
    assert_equal e.smaller_ontology, small_ontology
    assert_equal e.bigger_ontology, large_ontology
    assert e.go_on?
    
    # clear the alignment...
    FileUtils.rm(e.matcher.alignment_path)
    
    # sorry, all in one as the initialization takes like forever...
    e = Experimenter.new(small_ontology, large_ontology)
    pattern = Pattern.n_r_n_pattern(small_ontology, "http://ekaw/#Person", "http://ekaw/#authorOf", "http://ekaw/#Document", "Range Pattern")
    pattern2 = Pattern.n_r_n_pattern(small_ontology, "http://ekaw/#Person", "http://ekaw/#authorOf", "http://ekaw/#Document", "Range Pattern")    
    stats = e.get_stats_for_pattern_element(pattern.relation_constraints.first)
    assert_equal 1, stats[:matches]
    # we already have a match, so the cache should work...
    stats = e.get_stats_for_pattern_element(pattern.relation_constraints.first)
    assert_equal 0, stats[:matches]
    assert_equal 0, stats[:passes]    
    stats = e.get_stats_for_pattern_element(pattern2.relation_constraints.first)
    assert_equal 0, stats[:matches]
    assert_equal 0, stats[:passes]    
  end
  
end