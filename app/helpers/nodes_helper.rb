module NodesHelper

  def type_select(type_hierarchy, level=0)
    select = ""
    indent = ""
    
    level.times{|i| indent << "&nbsp;"}
    
    type_hierarchy.sort{|a,b| a.name <=> b.name}.each do |owl_class|
      indented_name = (indent + owl_class.name.split("#").last).html_safe
      select << options_for_select([[indented_name, owl_class.url]])
      select << type_select(owl_class.subclasses, level + 2)
    end
    
    return select.html_safe
  end
  
end
