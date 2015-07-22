module AggregationsHelper
  def operation_visuals(aggregation)
    case aggregation.operation
      when :group_by then fa_icon("sitemap", :text => aggregation.speaking_name)
      when :sum then "&sum; #{aggregation.speaking_name}"
      when :avg then "<span style='text-decoration: overline;'>#{aggregation.speaking_name}</span>"
      when :count then fa_icon("plus-circle", :text => aggregation.speaking_name)
    end
  end
end