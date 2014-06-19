module RepositoriesHelper
  def field_for_attribute(attribute, t_class, form)
    unless t_class.columns_hash[attribute].nil?
      self.send(("field_for_" + t_class.columns_hash[attribute].type.to_s).to_sym, attribute, form)
    else
      # this is for the simple-enum fields, which are not present in the columns hash, as is...
      field_for_enum(attribute, form, t_class)
    end
  end
  
  def field_for_string(attribute, form)
    return form.text_field(attribute)
  end
  
  def field_for_datetime(attribute, form)
    return form.datetime_select(attribute)
  end
  
  def field_for_integer(attribute, form)
    return form.number_field(attribute)
  end
  
  def field_for_boolean(attribute, form)
    return form.check_box(attribute)
  end
  
  def field_for_text(attribute, form)
    return form.text_area(attribute, {:rows => 5})
  end
  
  def field_for_enum(attribute, form, t_class)
    return form.select(attribute, options_from_collection_for_select(t_class.class_eval(attribute.pluralize).keys, "to_s", "to_s"))
  end
end
