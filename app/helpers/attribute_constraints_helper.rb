module AttributeConstraintsHelper
  def attrib_selector(possible_attributes)
    options_from_collection_for_select(possible_attributes, "attribute_url", "name")
  end
  
  # TODO: get a list from some model...
  def operator_selector
    options_from_collection_for_select(["?", "~=", "=", "<", ">", "!"], "to_s", "to_s")
  end
end
