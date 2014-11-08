class CorrespondenceExtractor
  attr_accessor :rule_engine, :source_pattern
  
  # TODO: substitute with RDF::Resource.new(xyz)
  C_PROP = "classification"
  
  # RULE IDENTIFIERS
  SG = "simple_graph"
  N_RC_N = "n-rc-n"
  N_AC = "n-ac"
  N_RC_N_RC_N = "n-rc-n-rc-n"
  
  def classify!(input_graph)
    reset!
    input_graph.each{|stmt| rule_engine << stmt}
  end
  
  def reset!
    @rule_engine = Wongi::Engine.create
    install_classification_rule_set!
  end
  
  # install the rules to classify the input and output graph
  def install_classification_rule_set!
    self.methods.select{|m| m.to_s.ends_with?("_rule")}.each do |rule_method|
      rule_engine << self.send(rule_method)
    end
  end
  
  # determine whether a graph only has one element
  def simple_graph_rule()
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
  def node_relation_node_rule()
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
  
  def node_attribute_constraint_rule()
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