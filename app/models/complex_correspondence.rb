class ComplexCorrespondence < SimpleCorrespondence
  include RdfSerialization

  def rdf_types
    [Vocabularies::Alignment.Cell]
  end

  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:alignments_path]
  end
  
  def output_element
    # TODO: build a pattern structure here
  end
  
end
