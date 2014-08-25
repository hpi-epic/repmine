module AttributeConstraintsHelper
  def attrib_selector(possible_attributes)
    options_from_collection_for_select(possible_attributes, "attribute_url", "name")
  end
  
  # TODO: get a list from some model...
  def operator_selector(list = nil)
    opts = list.nil? ? ["?", "~=", "=", "<", ">", "!"] : list
    options_for_select(opts)
  end
  
  def fixed_select(ac)
    options_for_select([[ac.attribute_name.split("/").last.split("#").last, ac.attribute_name]], ac.attribute_name)
  end
  
  
end
