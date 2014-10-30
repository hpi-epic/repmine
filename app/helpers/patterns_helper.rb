module PatternsHelper

  def static_select(pattern_element)
    options_for_select([[pattern_element.short_rdf_type, pattern_element.rdf_type]], pattern_element.rdf_type)
  end

end
