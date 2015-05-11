require 'objspace'

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

  # queries the graph in order to create an ontology that describes it...
  # 1. Get all nodes with certain labels and determine their properties + value types
  # 2. get all relations between different node types
  # 3. raise errors if we cannot reliably determine a "schema"  
  def create_ontology!
    properties = {}
    labels_and_counts.each_pair{|label, count| properties[label] = get_properties(label, count)}
    populate_ontology!(properties, get_relationships())
    return true
  end
    
  def get_relationships()
    return query_result("MATCH (a)-[r]->(b) RETURN labels(a)[0] AS This, type(r) as To, labels(b)[0] AS That, count(*) AS Count")
  end
  
  # yeah, sue me ... this is slow as f**k, but it does the job ^^
  def get_properties(label, count)
    offset = sensible_offset(label)
    rounds = (count / offset).to_i
    rounds += 1 if offset.modulo(count) != 0 || count < offset
    node_properties = {}
    rounds.times do |i|
      nodes = query_result("MATCH (n:`#{label}`) RETURN n SKIP #{offset * i} LIMIT #{offset}")
      nodes.collect{|node| node.first["data"]}.each{|bh| node_properties.merge!(bh.reject{|k,v| v.nil?})}
    end
    return node_properties
  end
  
  def sensible_offset(label)
    (10000000 / ObjectSpace.memsize_of(query_result("MATCH (n:`#{label}`) RETURN n LIMIT 1").first.first)).to_i
  end
  
  # Constructs an OWL ontology...
  def populate_ontology!(properties, relationships)
    properties.each_pair do |label, property_hash|
      owl_class = OwlClass.find_or_create(ontology, label, nil)
      property_hash.each_pair do |property_key, property_sample_value|
        owl_class.add_attribute(property_key, property_sample_value)
      end
    end
    
    # comes in arrays: 0: source, 1: name, 2: target, 3: count
    relationships.each do |relationship|
      domain = OwlClass.find_or_create(ontology, relationship[0], nil)
      range = OwlClass.find_or_create(ontology, relationship[2], nil)
      domain.add_relation(relationship[1], range)
    end
  end
  
  def labels_and_counts
    stats = Hash.new(0)
    res = query_result("START n=node(*) RETURN distinct labels(n), count(*)")
    res.each do |labels, count|
      if labels.is_a?(Array)
        labels.each{|label| stats[label] += count}
      else
        stats[labels] += count
      end
    end
    return stats    
  end

  def type_statistics
    return labels_and_counts.to_a
  end
  
  def query_result(query)
    return neo.execute_query(query)["data"]
  end
  
  # TODO: make more flexible... (https, security, all this stuf goes here ^^)
  def neo
    @neo ||= Neography::Rest.new("http://#{host}:#{port}")
  end
end