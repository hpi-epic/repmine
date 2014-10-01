module RdfSerialization
  
  def resource()
    return RDF::Resource.new(self.url)
  end
  
  def add_custom_property(property, value)
    @custom_properties ||= []
    @custom_properties << {:p => property, :v => value}
  end
  
  # this adds custom statements to the mix if the repository implementors need them
  def rdf
    custom_stmts = []
    unless @custom_properties.blank?
      @custom_properties.each do |cp|
        custom_stmts << [resource, cp[:p], cp[:v]]
      end
    end
    return custom_stmts.concat(all_rdf_statements)
  end
  
  def rdf_graph
    graph = RDF::Graph.new()
    rdf.each{|stmt| graph << stmt}
    return graph
  end
  
  def rdf_xml
    buffer = RDF::RDFXML::Writer.buffer(:prefixes => self.xml_prefixes) do |writer|
      writer.write_graph(rdf_graph)
    end
    return buffer
  end
  
  def xml_prefixes
    return {:rdfs => RDF::RDFS, :owl => RDF::OWL}.merge(custom_prefixes())
  end
  
  def all_rdf_statements
    return rdf_types.collect{|rdf_typ| [resource, RDF.type, rdf_typ]}.concat(rdf_statements)
  end
  
  def rdf_statements
    return []
  end
  
  def rdf_types
    []
  end
end