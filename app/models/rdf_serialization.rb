module RdfSerialization
  
  def resource()
    return RDF::Resource.new(self.url)
  end
  
  def add_custom_property(property, value)
    @custom_properties ||= []
    @custom_properties << {:p => property, :v => value}
  end
  
  # this adds custom statements to the mix if the repository implementors need them
  def all_statements
    stmts = []
    unless @custom_properties.blank?
      @custom_properties.each do |cp|
        stmts << [resource, cp[:p], cp[:v]]
      end
    end
    return statements.concat(stmts)
  end
end