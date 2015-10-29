module Vocabularies
  class Alignment < RDF::StrictVocabulary("http://knowledgeweb.semanticweb.org/heterogeneity/alignment")
    term :Alignment
    property :entity1
    property :entity2
    property :uri1
    property :uri2
    property :onto1
    property :onto2
    property :map
    property :relation
    property :measure
    property :part_of
    property :db_id
    term :Cell
  end
end
