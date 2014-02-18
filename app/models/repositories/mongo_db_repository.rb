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
      owl_class = add_class_to_schema(c_name.singularize.camelcase, schema)
      class_schema(get_schema_info(c_name), owl_class, schema)
    end
    return schema
  end
    
  def add_class_to_schema(name, schema)
    owl_class = OwlClass.new(ont_url, name.singularize.camelcase)
    schema.classes << owl_class
    return owl_class
  end
  
  # gets the schema for an entire class. This is done using the variety.js project to extract mongoDB 'schemas'
  def class_schema(info, owl_class, schema, key_prefix = "")        
    direct_ancestors(info, key_prefix).each do |inf|
      type = inf["value"]["type"]
      key = inf["_id"]["key"]
      descendants = all_descendants(info, key)    
      if not descendants.empty?
        target_class = add_class_to_schema(key.split(".").last, schema)
        class_schema(all_descendants(info, key), target_class, schema, key)
        owl_class.add_relation(key, target_class)
      else
        owl_class.add_attribute(key, type)
      end
    end
  end
  
  # select all direct ancestors with our prefix. We do this by counting dots. Not beautiful, but does the job
  def direct_ancestors(info, key_prefix)
    if key_prefix.empty?
      return info.select{|inf| inf["_id"]["key"].scan("\.").size == 0}
    else
      return info.select{|inf| 
        inf["_id"]["key"].starts_with?(key_prefix) && key_prefix.scan("\.").size == inf["_id"]["key"].scan("\.").size - 1
      }
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