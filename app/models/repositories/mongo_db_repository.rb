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
  
  def all_classes
    classes = []
    db.collection_names.each do |c_name|
      classes << OwlClass.new(c_name.singularize.camelcase)
    end
    return classes
  end
end