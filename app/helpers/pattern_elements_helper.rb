module PatternElementsHelper

  def name_field(pe)
    link_to(pe.name, "#", "data-url" => pattern_element_set_name_path(pe), "class" => "inplace", "data-pk" => pe.id)
  end

end