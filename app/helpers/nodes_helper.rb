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
      options.concat(select_list_options(owl_class.subclasses, level + 2))
    end

    return options
  end

  def node_position(node)
    if node.y == 0
      return "top: 10em;left: #{node.x == 0 ? 20 : node.x}px;"
    else
      return "top: #{node.y}px;left: #{node.x == 0 ? 20 : node.x}px;"
    end
  end
end
