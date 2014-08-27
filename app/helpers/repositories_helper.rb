module RepositoriesHelper
  def field_for_attribute(attribute, t_class, form)
    unless t_class.columns_hash[attribute].nil?
      self.send(("field_for_" + t_class.columns_hash[attribute].type.to_s).to_sym, attribute, form, t_class)
    else
      # this is for the simple-enum fields, which are not present in the columns hash, as is...
      field_for_enum(attribute, form, t_class)
    end
  end
  
  def field_for_string(attribute, form, t_class)
    return form.text_field(attribute, default_value(attribute, t_class))
  end
  
  def field_for_datetime(attribute, form, t_class)
    return form.datetime_select(attribute, default_value(attribute, t_class))
  end
  
  def field_for_integer(attribute, form, t_class)
    return form.number_field(attribute, default_value(attribute, t_class))
  end
  
  def field_for_boolean(attribute, form, t_class)
    return form.check_box(attribute, default_value(attribute, t_class))
  end
  
  def field_for_text(attribute, form, t_class)
    return form.text_area(attribute, default_value(attribute, t_class).merge({:rows => 5}))
  end
  
  def field_for_enum(attribute, form, t_class)
    return form.select(attribute, options_from_collection_for_select(t_class.class_eval(attribute.pluralize).keys, "to_s", "to_s"))
  end
  
  def default_value(attribute, t_class)
    if t_class.respond_to?("default_#{attribute}".to_sym)
      return {:value => t_class.send("default_#{attribute}".to_sym)}
    else
      return {}
    end
  end
end
