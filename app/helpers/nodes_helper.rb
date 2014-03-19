module NodesHelper

  def type_select(type_hierarchy)
    type_select = ""
    type_hierarchy.keys.sort.each do |url|
      owl_class = type_hierarchy[url]
      type_select << options_for_select([[owl_class.name, url]])
    end
    return type_select.html_safe
  end
  
end
