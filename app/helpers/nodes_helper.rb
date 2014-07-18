module NodesHelper

  def type_select(type_hierarchy, node)
    options = select_list_options(type_hierarchy)
    return options_for_select(options, node.rdf_type)
  end
  
  def select_list_options(type_hierarchy, level = 0)
    options = []
    indent = ""
    
    level.times{|i| indent << "&nbsp;"}
    
    type_hierarchy.sort{|a,b| a.name <=> b.name}.each do |owl_class|
      indented_name = (indent + owl_class.name.split("#").last).html_safe
      options << [indented_name, owl_class.url]
      options.concat(select_list_options(owl_class.subclasses, level + 2))
    end
    
    return options
  end
end
