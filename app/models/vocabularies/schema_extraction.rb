module Vocabularies
  class SchemaExtraction < RDF::StrictVocabulary(ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:schema_extraction_path])
    property :repository_datatype, :comment => 
    %(The datatype that a certain attribute or relation has within the target repository. 
    This is used to be able to define automatic conversion, e.g., if a data object is stored
    within a string instead of a date object)
    property :repository_database, :comment => %(A string that identifies the repositories database)
    property :repository_database_version, :comment => %(Version number of the repository database)

    # mongo db specific information
    property :mongo_db_collection_name, :comment => %(An attribute required for query generation. Denotes which 
    collection of the database schema contains elements of a certain class. This is implicitly clear for 
    certain elements (i.e., source elements) bot not for classes detected during extraction)

    property :mongo_db_navigation_path, :comment => %(We might find classes hidden deep within the document structure
    of a MongoDB. This property allows the query creator to access certain elements directly)
  end
end