class Pattern < Measurable

  include RdfSerialization

  attr_accessible :ontology_id
  attr_accessor :ag_connection, :layouted_graph

  has_and_belongs_to_many :ontologies
  has_many :pattern_elements, :dependent => :destroy
  has_many :target_patterns, :class_name => "Pattern", :foreign_key => "pattern_id"

  # validations
  validates :name, :presence => true
  validates :description, :presence => true
  validates :ontologies, :length => {:minimum => 1, :message=>"At least one ontology is required!" }

  # polymorphic finders....
  def nodes
    pattern_elements.where(:type => "Node")
  end

  def attribute_constraints
    pattern_elements.where(:type => "AttributeConstraint")
  end

  def relation_constraints
    pattern_elements.where(:type => "RelationConstraint")
  end

  # determines whether a pattern can already be executed on a given repository
  # case1: no element used in the pattern is from another ontology than the repository one
  # case2: a translation pattern exists and all input elements are matched to an output element
  def executable_on?(repository)
    return translation_unnecessary?(repository) || (translation_exists?(repository) && unmatched_elements([repository.ontology]).empty?)
  end

  def translation_unnecessary?(repository)
    (pattern_elements.collect{|pe| pe.ontology}.uniq - [repository.ontology]).empty?
  end

  def translation_exists?(repository)
    !TranslationPattern.existing_translation_pattern(self, [repository.ontology]).nil?
  end

  def create_node!(ontology, rdf_type = "")
    node = self.nodes.create!(:ontology_id => ontology.id)
    node.type_expression = TypeExpression.for_rdf_type(rdf_type)
    return node.becomes(Node)
  end

  def matched_elements(onts)
    PatternElement.where(:id => element_matches(onts).collect{|pem| pem.matched_element_id} & pattern_elements.pluck(:id))
  end

  def unmatched_elements(onts)
    PatternElement.where(:id => pattern_elements.pluck(:id) - element_matches(onts).collect{|pem| pem.matched_element_id})
  end

  def element_matches(onts)
    return PatternElementMatch.includes(:matching_element).where(
      :matched_element_id => pattern_elements,
      :pattern_elements => {:ontology_id => onts}
    )
  end

  # some comparison
  def equal_to?(other)
    if self == other
      return true
    else
      return self.pattern_elements.find{|pe| other.pattern_elements.select{|ope| pe.equal_to?(ope)}.size != 1}.nil?
    end
  end

  # RDF Serialization
  def rdf_statements
    return pattern_elements.collect{|pe| pe.rdf}.flatten(1)
  end

  def custom_prefixes()
    prefixes = {}
    ontologies.each{|ontology| prefixes[ontology.short_prefix] = ont.url}
    return prefixes
  end

  def print!
    puts "Pattern: #{self.name}"
    puts "Pattern Elements: #{pattern_elements.collect{|pe| pe.rdf_type}}"
  end

  # RDF deserialization
  def self.from_graph(graph, pattern_node, ont)
    pattern = Pattern.new()

    graph.build_query do |q|
      q.pattern([:element, Vocabularies::GraphPattern.belongsTo, :pattern])
      q.pattern([:element, RDF.type, :type])
      q.pattern([:type, RDF::RDFS.subClassOf, Vocabularies::GraphPattern.PatternElement])
    end.run do |res|
      # ugly, but agraph treats anonymous nodes in queries like wildcards. Hence, check on the results
      next if res[:pattern] != pattern_node
      pattern_element = Kernel.const_get(res[:type].to_s.split("/").last).new
      pattern_element.rdf_node = res[:element]
      pattern_element.pattern = pattern
      pattern_element.ontology = ont
      pattern.pattern_elements << pattern_element
    end

    pattern.pattern_elements.each{|pe| pe.rebuild!(graph)}
    return pattern
  end

  # Layouting
  def graphviz_graph
    g = GraphViz.new("#{id}", {:type => :digraph, :splines => true})
    node_cache = {}
    nodes.each do |node|
      node_cache[node] = g.add_node(node.id.to_s, {:label => node.pretty_string})
      node.attribute_constraints.each do |ac|
        ac_node = g.add_node(ac.id.to_s, {:shape => "box", :label => ac.pretty_string})
        g.add_edge(node_cache[node], ac_node)
      end
    end
    relation_constraints.each do |rc|
      g.add_edge(node_cache[rc.source], node_cache[rc.target], {:label => rc.pretty_string, :labeldistance => 10.0, :labelfloat => false})
    end
    return g
  end

  def auto_layout!()
    graphviz_graph.output(:dot => Rails.root.join("tmp", "pattern_layouts", "#{id}.dot"))
    graphviz_graph.output(:png => Rails.root.join("tmp", "pattern_layouts", "#{id}.png"))
    @layouted_graph = GraphViz.parse(Rails.root.join("tmp", "pattern_layouts", "#{id}.dot").to_s)
  end

  def store_auto_layout!()
    (nodes + attribute_constraints).each do |pe|
      pos = position_for_element(pe)
      pe.x = pos[0]
      pe.y = pos[1]
      pe.save!
    end
  end

  def position_for_element(element)
    point = layouted_graph.get_node(element.id.to_s)["pos"].point
    point[1] += 90
    point[1] *= 1.2
    point[0] *= 1.4
    return point
  end

  # determines which elements of a pattern will be returned by a query. No select *
  def returnable_elements(aggregations)
    if aggregations.blank?
      return nodes + attribute_constraints.select{|ac| ac.is_variable?}
    else
      return aggregations.collect{|agg| agg.pattern_element}
    end
  end

  def node_offset
    furthest = (nodes + attribute_constraints).sort_by{|pe| position_for_element(pe)[0]}.last
    return position_for_element(furthest)[0]
  end

  def layouted_graph
    @layouted_graph || auto_layout!
  end

  def url
    ONT_CONFIG[:ontology_base_url] + ONT_CONFIG[:patterns_path] + id.to_s
  end

  def rdf_types
    [Vocabularies::GraphPattern.GraphPattern]
  end

  def run_on_repository(repository)
    repository.results_for_pattern(self, [])
  end
end
