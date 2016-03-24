module ApplicationHelper
  def div_id(something)
    return something.class.name.underscore.downcase + "_#{something.id}"
  end

  def ontology_select(ontologies)
    select_tag(:ontology_id, options_for_select(ontologies.collect{|ont| [ont.short_name, ont.id]}),class: "needs_no_space")
  end
end