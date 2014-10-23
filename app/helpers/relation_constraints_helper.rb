module RelationConstraintsHelper
  def static_select(rc)
    options_for_select([[rc.short_rdf_type, rc.rdf_type]], rc.rdf_type)
  end
end
