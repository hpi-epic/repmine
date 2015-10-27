module ApplicationHelper
  def div_id(something)
    return something.class.name.underscore.downcase + "_#{something.id}"
  end
end