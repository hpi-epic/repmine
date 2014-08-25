module RelationConstraintsHelper
  def static_select(rc)
    options_for_select([[rc.relation_type.split("/").last.split("#").last,rc.relation_type]], rc.relation_type)
  end
end
