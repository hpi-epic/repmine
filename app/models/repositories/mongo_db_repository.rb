class MongoDbRepository < Repository
  attr_accessible :database_name

  def self.model_name
    return Repository.model_name
  end
  
  def db
    @mongo_client ||= Mongo::MongoClient.new(self.host) 
    @db ||= @mongo_client.db(self.database_name)
    return @db
  end
  
  def get_type_stats
    stats = []
    db.collection_names.each do |c_name|
      stats << [c_name, db[c_name].find().count()]
    end
    return stats
  end
  
  def extract_schema(schema)
    db.collection_names.each do |c_name|
      owl_class = OwlClass.new(schema, name.singularize.camelcase)
      class_schema(get_schema_info(c_name), owl_class, schema)
    end
    return schema
  end
  
  # gets the schema for an entire class. This is done using the variety.js project to extract mongoDB 'schemas'
  def class_schema(info, owl_class, schema, key_prefix = "")
    relations = info.select{|inf| inf["value"]["type"] == "Array"}
    attributes = info.reject{|inf| 
      relations.include?(inf) || !relations.find{|rel| inf["_id"]["key"].starts_with?(rel["_id"]["key"])}.nil? 
    }
    
    relations.each do |rel|
      key = rel["_id"]["key"]
      target_class = OwlClass.new(schema, key.split(".").last)
      class_schema(all_descendants(info, key), target_class, schema, key)
      owl_class.add_relation(key, target_class)
    end
    
    attributes.each do |attrib|
      owl_class.add_attribute(attrib["_id"]["key"].gsub(".XX", ""), attrib["value"]["type"])
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
    return db.eval(info_js, collection_name)
  end
end