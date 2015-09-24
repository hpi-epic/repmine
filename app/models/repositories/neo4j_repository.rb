class Neo4jRepository < Repository

  attr_accessor :neo

  def self.model_name
    return Repository.model_name
  end

  def self.rdf_format
    "rdf"
  end

  def self.default_port
    7474
  end

  def self.query_creator_class
    CypherQueryCreator
  end

  # queries the graph in order to create an ontology that describes it...
  # 1. Get all nodes with certain labels and determine their properties + value types
  # 2. get all relations between different node types
  def analyze_repository()
    properties = {}
    properties = get_properties(labels_and_counts.keys)
    populate_ontology!(properties, get_relationships())
    log_status("Finished analyzing the ontology! Classes found: #{ontology.classes.size}", 100)
    ontology.update_attributes({:does_exist => true})
    ontology.load_to_dedicated_repository!
  end

  def create_ontology!
    if ontology_creation_job.nil?
      lc = labels_and_counts
      j = OntologyExtractionJob.new(progress_max: 100, repository_id: self.id)
      Delayed::Job.enqueue(j, :queue => ont_creation_queue)
    end
    return nil
  end

  def get_properties(labels)
    all_props = neo.connection.get("/propertykeys")
    properties = {}

    labels.each_with_index do |label, i|
      all_props.each do |prop|
        res = query_result("MATCH (n:`#{label}`) WHERE has(n.#{prop}) AND n.#{prop} IS NOT NULL RETURN n.#{prop} LIMIT 1")
        res.each do |res_row|
          properties[label] ||= {}
          properties[label][prop] = res_row.first
        end
      end
      log_status("Found #{properties[label].size} properties for '#{label}'.", (70.0 / labels.size) * 1)
    end

    return properties
  end

  # Constructs an OWL ontology...
  def populate_ontology!(properties, relationships)
    log_status("Adding all properties to the ontology!", 80)
    properties.each_pair do |label, property_hash|
      owl_class = OwlClass.find_or_create(ontology, label, nil)
      property_hash.each_pair do |property_key, property_sample_value|
        owl_class.add_attribute(property_key, property_sample_value)
      end
    end

    # comes in arrays: 0: source, 1: name, 2: target, 3: count
    log_status("Adding #{relationships.size} relationships to the ontology!", 90)
    relationships.each do |relationship|
      domain = OwlClass.find_or_create(ontology, relationship[0], nil)
      range = OwlClass.find_or_create(ontology, relationship[2], nil)
      domain.add_relation(relationship[1], range)
    end
  end

  def get_relationships()
    return query_result("MATCH (a)-[r]->(b) RETURN labels(a)[0] AS This, type(r) as To, labels(b)[0] AS That, count(*) AS Count")
  end

  def labels_and_counts
    stats = Hash.new(0)
    query_result("MATCH (n) RETURN distinct labels(n), count(*)").each do |res|
      res[0].each{|label| stats[label] += res[1]}
    end
    return stats
  end

  def type_statistics
    return labels_and_counts.to_a
  end

  def query_result(query, columns = false)
    tx = neo.begin_transaction(query)
    raise tx["errors"].first["message"] unless tx["errors"].empty?
    neo.commit_transaction(tx)
    if !columns
      return tx["results"].first["data"].collect{|row| row["row"]}
    else
      return tx["results"].first["data"].collect{|row| row["row"]}, tx["results"].first["columns"]
    end
  end

  def neo
    @neo ||= Neography::Rest.new("http://#{host}:#{port}")
  end

  def results_for_query(query)
    data = []
    columns = []
    round = 0

    loop do
      round_data, round_columns = query_result(query + " SKIP #{round*1000} LIMIT 1000", true)
      data += round_data
      columns = round_columns
      log_msg("Results so far: #{data.size}")
      round += 1
      break if round_data.size != 1000
    end

    return hash_data(data, columns)
  end

  def hash_data(data, columns)
    return data.collect do |row|
      Hash[ *row.enum_for(:each_with_index).collect{|val, i| [ columns[i], val ] }.flatten ]
    end
  end
end