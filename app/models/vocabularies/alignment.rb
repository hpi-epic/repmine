module Vocabularies
  class Alignment < RDF::StrictVocabulary("http://knowledgeweb.semanticweb.org/heterogeneity/alignment")
    property :entity1
    property :entity2
    property :uri1
    property :uri2
    property :onto1
    property :onto2
    property :map
    property :relation
    property :measure
    property :Cell
  end 
end
