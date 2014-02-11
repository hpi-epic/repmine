class AgraphConnection
  
  attr_accessor :repository, :repository_name
  
  def config
    return RepMine::Application.config.database_configuration["agraph"]
  end
  
  def initialize(repo_name)
    @repository_name = repo_name
  end

  def repository_url()
    url = config["protocol"] + "://" + config["username"] + ":" + config["password"] + "@"
    url += config["host"] + ":" + config["port"].to_s + "/repositories/" + repository_name
    return url
  end
  
  def repository(create = true)
    @repository ||= RDF::AllegroGraph::Repository.new(self.repository_url, :create => create)
    return @repository
  end
  
  def insert_graph!(rdf_graph)
    repository.insert(rdf_graph.statements)
  end
  
  def remove_duplicates!()
    RestClient.delete(self.repository_url + "/statements/duplicates?mode=spog")
  end
  
  def delete!()
    repository.delete!
    @repository = nil
  end
  
  def relations_between(source, target)
    outbound = relations_with(source, target)
    inbound = relations_with(target, source)
    return {
      "inbound" => inbound - outbound,
      "outbound" => outbound - inbound,
      "bidirectional" => outbound & inbound
    }
  end
  
  def relations_with(domain, range)
    rels = Set.new
    
    repository.build_query(:infer => true) do |q|
      q.pattern([:rel, RDF.type, RDF::OWL.ObjectProperty])
      q.pattern([:rel, RDF::RDFS.domain, RDF::Resource.new(domain)])
      q.pattern([:rel, RDF::RDFS.range, RDF::Resource.new(range)])
    end.run do |res|
      rels << res.rel.to_s
    end
    
    return rels.to_a
  end
  
  def attributes_for(node_class)
    attribs = Set.new
    
    [node_class].concat(get_all_superclasses(node_class)).each do |clazz|
      repository.build_query(:infer => true) do |qq|
        qq.pattern([:attrib, RDF.type, RDF::OWL.DatatypeProperty])
        qq.pattern([:attrib, RDF::RDFS.domain, RDF::Resource.new(clazz)])
        qq.pattern([:attrib, RDF::RDFS.range, :range], :optional => true)
      end.run do |res2|
        attribs << {:uri => res2.attrib.to_s, :range => res2.bound?(:range) ? res2.range.to_s : nil}
      end
    end
    
    return attribs
  end
  
  def get_all_superclasses(rdf_class)
    superclasses = Set.new
    
    repository.build_query(:infer => true) do |q|
      q.pattern([RDF::Resource.new(rdf_class), RDF::RDFS.subClassOf, :clazz])
    end.run{|res| superclasses << res.clazz.to_s}
    
    return superclasses.to_a
  end
  
  def type_hierarchy
    classes = {}
    subclasses = Set.new
    
    # get all classes and - if present - their subclasses
    repository.build_query() do |q|
      q.pattern([:clazz, RDF.type, RDF::OWL.Class])      
      q.pattern([:sub_clazz, RDF::RDFS.subClassOf, :clazz], :optional => true)
    end.run do |stmt|
      clazz = classes[stmt.clazz.to_s] ||= OwlClass.new(stmt.clazz.to_s)
      if stmt.bound?(:sub_clazz)
        sub_clazz = classes[stmt.sub_clazz.to_s] ||= OwlClass.new(stmt.sub_clazz.to_s)
        clazz.subclasses << sub_clazz
        subclasses << stmt.sub_clazz.to_s
      end
    end
    
    subclasses.each{|sc| classes.delete(sc)}
    return classes
  end
end