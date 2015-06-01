module AttributeConstraintsHelper
  def attrib_selector(possible_attributes)
    options_from_collection_for_select(possible_attributes.sort{|a,b| a.name <=> b.name}, "attribute_url", "name")
  end

  def operator_selector(list = nil)
    opts = list.nil? ? AttributeConstraint::OPERATORS.values : list
    options_for_select(opts)
  end

  def ac_position(ac)
    if ac.y == 0 && ac.x == 0
      return ""
    else
      return "top: #{ac.y}px;left: #{ac.x == 0 ? 20 : ac.x}px;"
    end
  end

end
