module AttributeConstraintsHelper
  def attrib_selector(possible_attributes, ac = nil)
    attrs = possible_attributes.sort{|a,b| a.name <=> b.name}
    options_from_collection_for_select(attrs, "attribute_url", "name", ac.nil? ? nil : ac.rdf_type)
  end

  def ac_position(ac, relayout = false)
    x,y = relayout ? ac.pattern.position_for_element(ac) : [ac.x, ac.y]
    if y == 0 && x == 0
      return ""
    else
      return "top: #{y}px;left: #{x == 0 ? 20 : x}px;"
    end
  end

end
