module AggregationsHelper
  def operation_visuals(aggregation)
    vname = aggregation.pattern_element.speaking_name 
    case aggregation.operation
      when :group_by then fa_icon("sitemap", :text => vname)
      when :sum then "&sum; #{vname}"
      when :avg then "<span style='text-decoration: overline;'>#{vname}</span>"
      when :count then fa_icon("plus-circle", :text => vname)
    end
  end
end