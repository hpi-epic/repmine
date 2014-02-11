module RepositoriesHelper
  def field_for_attribute(attribute, t_class, form)
    self.send(("field_for_" + t_class.columns_hash[attribute].type.to_s).to_sym, attribute, form)
  end
  
  def field_for_string(attribute, form)
    return form.text_field(attribute)
  end
  
  def field_for_datetime(attribute, form)
    
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
end
