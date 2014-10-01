class MongoDbRepository < Repository
  COLLECTION_BLACKLIST = ["system.indexes"]
  
  def self.rdf_format
    "rdf"
  end
  
  def self.default_port
    27017
  end

  def self.model_name
    return Repository.model_name
  end
  
  def db
    @mongo_client ||= Mongo::MongoClient.new(self.host) 
    @db ||= @mongo_client.db(self.db_name)
    return @db
  end
  
  def get_type_stats
    stats = []
    db.collection_names.each do |c_name|
      stats << [c_name, db[c_name].find().count()]
    end
    return stats
  end
  
  def create_ontology!
    ontology.clear!
    db.collection_names.each do |c_name|
      next if COLLECTION_BLACKLIST.include?(c_name)
      owl_class = OwlClass.new(ontology, c_name.singularize.camelcase)
      class_schema(get_schema_info(c_name), owl_class, c_name)
    end
    ontology.download!    
  end
  
  # gets the schema for an entire class. This is done using the variety.js project to extract mongoDB 'schemas'
  def class_schema(info, owl_class, collection_name)
    relations = info.select{|inf| inf["value"]["type"] == "Array"}
    attributes = info.reject{|inf| 
      relations.include?(inf) || !relations.find{|rel| inf["_id"]["key"].starts_with?(rel["_id"]["key"])}.nil?
    }
    
    relations.each do |rel|
      key = rel["_id"]["key"].gsub(".XX", "")
      target_class = OwlClass.new(ontology, key.split(".").last.singularize.camelcase)
      target_class.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new(collection_name))
      class_schema(all_descendants(info, key), target_class, key)
      r = owl_class.add_relation(key, target_class)
      r.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_navigation_path, RDF::Literal.new(key))
      r.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new(collection_name))
    end
    
    attributes.each do |attrib|
      clean_name = attrib["_id"]["key"]
      a = owl_class.add_attribute(clean_name, attrib["value"]["type"])
      a.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_navigation_path, RDF::Literal.new(attrib["_id"]["key"].gsub(".XX", "")))
      a.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new(collection_name))
    end
  end
  
  # selects all elements that are below a given one
  def all_descendants(info, key_prefix)
    if key_prefix.empty?
      return info
    else
      return info.select{|inf|
        inf["_id"]["key"].starts_with?(key_prefix + ".") && inf["_id"]["key"].size > key_prefix.size
      }
    end
  end
  
  def get_schema_info(collection_name)
    info_js = File.open(Rails.root.join("public","javascripts","variety.js")).read    
    return db.eval(info_js, collection_name, 20000)
  end
  
  def database_type
    "MongoDB"
  end
  
  def database_version
    # TODO: get this information from the database itself
    return "2.4"
  end
end