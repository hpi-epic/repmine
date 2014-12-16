class Oracle
  attr_accessor :om_comp, :om_reference
  
  def initialize(o1, o2, alignment_path)
    @om_computed = OntologyMatcher.new(o1,o2, true)
    @om_reference = OntologyMatcher.new(o1,o2)
    @om_reference.add_to_alignment_graph!(alignment_path)
  end
  
  def substitutes_for(pattern_elements)
    return @om_reference.substitutes_for(pattern_elements, false)
  end
  
  def do_you_know_more?
    om_computed.matched_concepts[:correspondence_count] < om_reference.matched_concepts[:correspondence_count]
  end
  
  def do_i_know_more?
    om_computed.matched_concepts[:correspondence_count] > om_reference.matched_concepts[:correspondence_count]
  end
  
  def call_it_a_tie?
    om_computed.matched_concepts[:correspondence_count] == om_reference.matched_concepts[:correspondence_count]
  end
end
