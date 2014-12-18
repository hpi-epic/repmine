module AttributeConstraintsHelper
  def attrib_selector(possible_attributes)
    options_from_collection_for_select(possible_attributes.sort{|a,b| a.name <=> b.name}, "attribute_url", "name")
  end

  def operator_selector(list = nil)
    opts = list.nil? ? AttributeConstraint::OPERATORS.values : list
    options_for_select(opts)
  end

end
