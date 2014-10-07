class CorrespondenceExtractor
  attr_accessor :rule_engine
  
  CLASSIFICATION_RULES = [:simple_graph]#, :node_relation_node, :node_attribute]
  
  def extract_correspondences!(input_graph)
    reset!
    input_graph.each{|stmt| rule_engine << stmt}
  end
  
  def reset!
    @rule_engine = Wongi::Engine.create
    install_classification_rule_set!
  end
  
  # install the rules to classify the input and output graph
  def install_classification_rule_set!
    CLASSIFICATION_RULES.each{|cr| rule_engine << self.send("#{cr}_rule".to_sym)}
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
        gen(:Graph, "classification", "simple")
      }
    end
  end
  
  def node_relation_node_rule()
    rule("n-r-n") do
      forall {
        has(:Relation, Vocabularies::GraphPattern.belongsTo, :Graph)
        has(:Relation, RDF.type, Vocabularies::GraphPattern.RelationConstraint)
        has(:Node, Vocabularies::GraphPattern.outgoingRelation, :Relation)
        has(:Node2, Vocabularies::GraphPattern.incomingRelation, :Relation)
        none {
          has(:Diff, Vocabularies::GraphPattern.belongsTo, :Graph)
          # different thatn Node, Node2, or Relation
        }
      }
      make {
        gen(:Graph, "classification", "simple")
      }
    end
  end
end
