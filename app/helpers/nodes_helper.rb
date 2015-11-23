module NodesHelper

  def type_select(type_hierarchy, node)
    options = select_list_options(type_hierarchy)
    unless node.is_a?(TypeExpression)
      fstring = node.type_expression.fancy_string
      if !fstring.blank? && options.find{|o| o.last == fstring}.nil?
        options << [node.type_expression.fancy_string(true), node.type_expression.fancy_string]
      end
    end
    return options_for_select(options, node.rdf_type)
  end

  def select_list_options(type_hierarchy, level = 0)
    options = []
    indent = ""

    level.times{|i| indent << "&nbsp;"}

    type_hierarchy.sort{|a,b| a.name <=> b.name}.each do |owl_class|
      indented_name = (indent + owl_class.name.split("#").last).html_safe
      options << [indented_name, owl_class.url]
      options.concat(select_list_options(owl_class.subclasses, level + 1))
    end

    return options
  end

  def node_position(node, relayout = false, offset = 0)
    x,y = relayout ? node.pattern.position_for_element(node) : [node.x, node.y]
    x += offset
    if y == 0
      return "top: 10em;left: #{x == 0 ? 20 : x}px;"
    else
      return "top: #{y}px;left: #{x == 0 ? 20 : x}px;"
    end
  end
end
