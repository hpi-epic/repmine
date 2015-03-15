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

  def insert_file!(rdf_file)
    repository.load(rdf_file)
    remove_duplicates!
  end

  def remove_duplicates!()
    RestClient.delete(self.repository_url + "/statements/duplicates?mode=spog")
  end

  def delete!()
    repository(false).delete!
    @repository = nil
  end

  def clear!
    repository().clear
  end
  
  # at some point, this could be replaced with a fancy SPARQL query...
  def relations_with(domain, range)
    rels = []
    ([domain] + get_all_superclasses(domain)).each do |ddomain|
      ([range] + get_all_superclasses(range)).each do |rrange|
        rels.concat(relations(ddomain, rrange) - rels)
      end
    end
    return rels
  end

  def outgoing_relations(domain)
    relations(domain, nil)
  end

  def incoming_relations(range)
    relations(nil, range)
  end
  
  def relations(domain, range)
    rels = []
    repository.build_query(:infer => true) do |q|
      q.pattern([:rel, RDF.type, RDF::OWL.ObjectProperty])
      q.pattern([:rel, RDF::RDFS.domain, domain.nil? ? :domain : RDF::Resource.new(domain)])
      q.pattern([:rel, RDF::RDFS.range, range.nil? ? :range : RDF::Resource.new(range)])
      q.pattern([:range, RDF::OWL.unionOf, :list], :optional => true)
    end.run do |res|
      rel = Relation.from_url(
        res.rel.to_s, 
        domain.nil? ? res.domain : domain, 
        range.nil? ? (res.bound?(:list) ? decipher_union(res.list) : [res.range]) : [range]
      )
      rels << rel unless rels.include?(rel)
    end
    return rels
  end

  # gets the attribuets whose domain is the given class or any of its top classes
  def attributes_for(node_class)
    attribs = []

    [node_class].concat(get_all_superclasses(node_class)).each do |clazz|
      domain = OwlClass.new(nil, nil, clazz)
      repository.build_query(:infer => true) do |qq|
        qq.pattern([:attrib, RDF.type, RDF::OWL.DatatypeProperty])
        qq.pattern([:attrib, RDF::RDFS.domain, RDF::Resource.new(clazz)])
        qq.pattern([:attrib, RDF::RDFS.range, :range], :optional => true)
      end.run do |res|
        attrib = Attribute.from_url(res.attrib.to_s, res.bound?(:range) ? res.range : nil, domain)
        attribs << attrib unless attribs.include?(attrib)
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

  def element_class_for_rdf_type(rdf_type)
    repository.build_query(:infer => true) do |q|
      q.pattern([RDF::Resource.new(rdf_type), RDF.type, :clazz])
    end.run do |res|
      clazz = case res[:clazz]
        when RDF::OWL.Class then Node
        when RDF::RDFS.Class then Node
        when RDF::OWL.DatatypeProperty then AttributeConstraint
        when RDF::OWL.ObjectProperty then RelationConstraint
        else PatternElement
      end
      return clazz
    end
    
    return PatternElement
  end

  # gets the entire type hierarchy from an ontology. ditches anonymous classes (e.g., owl:unions as the users should provide them)
  def type_hierarchy(ontology = nil)
    classes = {}
    subclasses = Set.new

    # get all classes and - if present - their subclasses
    repository.build_query() do |q|
      q.pattern([:clazz, RDF.type, RDF::OWL.Class])
      q.pattern([:sub_clazz, RDF::RDFS.subClassOf, :clazz], :optional => true)
    end.run do |stmt|
      cname = stmt.clazz.to_s.split("/").last
      next if stmt.clazz.anonymous?
      clazz = classes[stmt.clazz.to_s] ||= OwlClass.new(ontology, cname, stmt.clazz.to_s)
      if stmt.bound?(:sub_clazz)
        scs = stmt.sub_clazz.anonymous? ? decipher_union(stmt.sub_clazz) : [stmt.sub_clazz.to_s]
        scs.each do |sub_class|
          sub_clazz = classes[sub_class] ||= OwlClass.new(ontology, sub_class.split("/").last, sub_class)
          clazz.add_subclass(sub_clazz)
          subclasses << sub_class
        end
      end
    end

    subclasses.each{|sc| classes.delete(sc)}
    return classes.values
  end
  
  # this is slow as hell ... TODO: figure out how to get the entire collection through agraph
  def decipher_union(union_node)
    classes = []
    un = union_node
    while(un != RDF.nil.to_s)
      stmts = repository.statements.select{|stmt| stmt.subject == un}
      break if stmts.find{|stmt| stmt.predicate == RDF.first}.nil?
      classes << stmts.find{|stmt| stmt.predicate == RDF.first}.object.to_s
      un = stmts.find{|stmt| stmt.predicate == RDF.rest}.object
    end
    return classes
  end
end