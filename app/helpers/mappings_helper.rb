module MappingsHelper
  def rdf_type_options(mapping)
    vocs = ExtractionDescription.all.collect{|ed| RDF::Vocabulary.new(ed.target_ontology_url)}
    vocabularies = RDF::Vocabulary.find_all.to_a - [RDF] + vocs
    return options_from_collection_for_select(vocabularies.collect{|v| v.to_s}, "to_s", "to_s", mapping.element_type_vocabulary)
  end
end
