require 'objspace'

class Neo4jRepository < Repository

  attr_accessor :neo

  def self.model_name
    return Repository.model_name
  end

  def self.default_port
    7474
  end

  # queries the graph in order to create an ontology that describes it...
  # 1. Get all nodes with certain labels and determine their properties + value types
  # 2. get all relations between different node types
  # 3. raise errors if we cannot reliably determine a "schema"  
  def create_ontology!
    labels = Hash[ *type_statistics.collect { |v| [ v[0], v[1] ] }.flatten ]

    properties = {}
    labels.each_pair do |label, count|
      properties[label] = get_properties(label, count)
    end
    build_owl(labels, properties, get_relationships())
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
  def build_owl(labels, properties, relationships)
    
  end

  def type_statistics
    return query_result("START n=node(*) RETURN distinct labels(n), count(*)")
  end
  
  def query_result(query)
    return neo.execute_query(query)["data"]
  end
  
  # TODO: make more flexible... (https, security, all this stuf goes here ^^)
  def neo
    @neo ||= Neography::Rest.new("http://#{host}:#{port}")
  end
end