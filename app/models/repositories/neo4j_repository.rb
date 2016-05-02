class Neo4jRepository < Repository

  attr_accessor :neo

  def self.rdf_format
    "rdf"
  end

  def self.default_port
    7474
  end

  def query_creator_class
    CypherQueryCreator
  end

  def neo
    @neo ||= Neography::Rest.new("http://#{db_username}:#{db_password}@#{host}:#{port}")
  end

  # queries the graph in order to create an ontology that describes it...
  # 1. Get all nodes with certain labels and determine their properties + value types
  # 2. get all relations between different node types
  def analyze_repository
    properties = {}
    properties = get_properties(neo.list_labels)
    populate_ontology!(properties, get_relationships())
    log_status("Finished analyzing the ontology! Classes found: #{ontology.classes.size}", 100)
    ontology.update_attributes({:does_exist => true})
    ontology.load_to_dedicated_repository!
  end

  def get_properties(labels)
    all_props = neo.connection.get("/propertykeys")
    properties = {}

    labels.each_with_index do |node_label, i|
      all_props.each do |prop|
        res = query_result("MATCH (n:`#{node_label}`) WHERE n.#{prop} IS NOT NULL RETURN n.#{prop} LIMIT 1")
        res.each do |res_row|
          properties[node_label] ||= {}
          properties[node_label][prop] = res_row.first
        end
      end
      log_status("Found #{properties[node_label].size} properties for '#{node_label}'.", (70.0 / labels.size) * 1)
    end

    return properties
  end

  # Constructs an OWL ontology...
  def populate_ontology!(properties, relationships)
    log_status("Adding all properties to the ontology!", 80)
    properties.each_pair do |node_label, property_hash|
      owl_class = OwlClass.find_or_create(ontology, node_label, nil)
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
    neo.list_relationship_types.collect do |rel_type|
      query_result("MATCH (a)-[r:`#{rel_type}`]->(b) RETURN labels(a)[0], type(r), labels(b)[0]LIMIT 1").flatten
    end
  end

  def type_statistics
    stats = Hash.new(0)
    query_result("MATCH (n) RETURN distinct labels(n), count(*)").each do |res|
      res[0].each{|label| stats[label] += res[1]}
    end
    return stats.to_a
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

  def results_for_query(query)
    start = Time.now
    log_msg("Starting Query: #{query}")
    data, columns = query_result(query, true)
    log_msg("Received #{data.size} results in #{(Time.now - start).round(3)}s")
    return hash_data(data, columns)
  end

  def hash_data(data, columns)
    return data.collect do |row|
      Hash[ *row.collect.with_index{|val, i| [ columns[i], val ] }.flatten ]
    end
  end
end