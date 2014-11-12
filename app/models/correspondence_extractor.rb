class CorrespondenceExtractor
  # TODO: substitute with RDF::Resource.new(xyz)
  C_PROP = "classification"
  M_PROP = "correspondsTo"
  IM_PROP = "inferredCorrespondsTo"
  
  
  # RULE IDENTIFIERS
  SG = "simple_graph"
  N_RC_N = "n-rc-n"
  N_AC = "n-ac"
  N_RC_N_RC_N = "n-rc-n-rc-n"
  
  def classify(pattern)
    c_engine = clean_classification_engine
    pattern.rdf.each{|stmt| c_engine << stmt}
    return c_engine
  end
  
  def detect_missing_correspondences!(input_pattern, output_pattern)
    i_engine = clean_inference_engine
    [classify(input_pattern), classify(output_pattern)].each{|g| g.each{|stmt| i_engine << stmt}}
    
    # inserts the matching relations into the engine. the already present rules will use them to, e.g., find missing links
    input_pattern.pattern_elements.each do |pe|
      OntologyCorrespondence.includes(:input_elements).where(:pattern_elements => {:id => pe.id}).each do |corr|
        corr.output_elements.each{|oe| i_engine << [pe.resource, M_PROP, oe.resource]}
      end
    end
    
    # finds the newly created correspondences and adds them to our knwoledge base
    i_engine.select(:Input, CorrespondenceExtractor::IM_PROP, :Output).each do |res|
      OntologyCorrespondence.for_elements!([PatternElement.find_by_url(res.subject.to_s)], [PatternElement.find_by_url(res.object.to_s)])
    end
    
    return i_engine
  end
  
  # install the rules to classify the input and output graph
  def clean_classification_engine
    classification_engine = Wongi::Engine.create
    self.methods.select{|m| m.to_s.ends_with?("_crule")}.each do |rule_method|
      classification_engine << self.send(rule_method)
    end
    return classification_engine
  end
  
  def clean_inference_engine
    inference_engine = Wongi::Engine.create
    self.methods.select{|m| m.to_s.ends_with?("_irule")}.each do |rule_method|
      inference_engine << self.send(rule_method)
    end
    return inference_engine
  end
  
  # figures out that a link is missing and inserts it
  def missing_link_irule()
    rule("missing_link") do
      forall {
        # input_graph
        has(:Relation1, RDF.type, Vocabularies::GraphPattern.RelationConstraint)
        has(:Node1, Vocabularies::GraphPattern.outgoingRelation, :Relation1)
        has(:Node2, Vocabularies::GraphPattern.incomingRelation, :Relation1)
        # output_graph
        has(:Relation2, RDF.type, Vocabularies::GraphPattern.RelationConstraint)
        has(:Node3, Vocabularies::GraphPattern.outgoingRelation, :Relation2)
        has(:Node4, Vocabularies::GraphPattern.incomingRelation, :Relation2)
        # mapping
        has(:Node1, M_PROP, :Node3)
        has(:Node2, M_PROP, :Node4)
        neg(:Relation1, M_PROP, :anything)
      }
      make {
        gen(:Relation1, IM_PROP, :Relation2)
      }
    end
  end
  
  # determine whether a graph only has one element
  def simple_graph_crule()
    rule("simple_graph") do
      forall {
        has(:Graph_element, Vocabularies::GraphPattern.belongsTo, :Graph)
        none {
          has(:Different_element, Vocabularies::GraphPattern.belongsTo, :Graph)
          diff(:Graph_element, :Different_element)
        }
      }
      make {
        gen(:Graph, C_PROP, SG)
      }
    end
  end

  # identifies node-relation->node subgraphs
  def node_relation_node_crule()
    rule(N_RC_N) do
      forall {
        has(:Relation, Vocabularies::GraphPattern.belongsTo, :Graph)
        has(:Relation, RDF.type, Vocabularies::GraphPattern.RelationConstraint)
        has(:Node, Vocabularies::GraphPattern.outgoingRelation, :Relation)
        has(:Node2, Vocabularies::GraphPattern.incomingRelation, :Relation)
      }
      make {
        gen(:Graph, C_PROP, N_RC_N)
      }
    end
  end
  
  def node_attribute_constraint_crule()
    rule(N_AC) do
      forall {
        has(:Ac, Vocabularies::GraphPattern.belongsTo, :Graph)
        has(:Ac, RDF.type, Vocabularies::GraphPattern.AttributeConstraint)
        has(:Node, Vocabularies::GraphPattern.attributeConstraint, :Ac)
      }
      make {
        gen(:Graph, C_PROP, N_AC)
      }
    end
  end
end