module RdfSerialization
  
  def resource()
    return RDF::Resource.new(self.uri)
  end
  
end