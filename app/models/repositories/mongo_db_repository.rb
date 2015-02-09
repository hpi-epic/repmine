# == Schema Information
#
# Table name: repositories
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  db_name       :string(255)
#  db_username   :string(255)
#  db_password   :string(255)
#  host          :string(255)
#  port          :integer
#  description   :text
#  ontology_id   :integer
#  type          :string(255)
#  rdbms_type_cd :integer
#

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

  def type_statistics
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
      class_schema(get_schema_info(c_name), c_name)
    end
    ontology.remove_local_copy!
    ontology.download!
  end

  # gets the schema for an entire class. This is done using the variety.js project to extract mongoDB 'schemas'
  def class_schema(info, collection_name)
    # first the base class for the collection
    class_name = collection_name.singularize.camelcase
    owl_class = OwlClass.new(ontology, class_name, ontology.url + "/" + class_name)
    info.each do |attrib|
      type = attrib["value"]["type"]
      key = attrib["_id"]["key"]
      next if type == "Object" || key == "_id"

      a = owl_class.add_attribute(key, type)
      a.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_navigation_path, RDF::Literal.new(key))
      a.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_collection_name, RDF::Literal.new(collection_name))
      a.add_custom_property(Vocabularies::SchemaExtraction.mongo_db_is_array, RDF::Literal.new(type == "Array"))
    end
  end

  def get_schema_info(collection_name)
    puts "starting js query for #{collection_name}"
    info_js = File.open(Rails.root.join("public","javascripts","variety.js")).read
    info_hash = db.eval(info_js, collection_name, 20000)
    puts "js query done for #{collection_name}"
    info_hash.each{|info| info["_id"]["key"] = info["_id"]["key"].gsub(".XX", "")}
    return info_hash
  end

  def database_type
    "MongoDB"
  end

  def self.query_creator_class
    MongoDbQueryCreator
  end

  def database_version
    # TODO: get this information from the database itself
    return "2.4"
  end
end
