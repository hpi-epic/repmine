class CorrespondenceExtractor
  attr_accessor :rule_engine
  
  def initialize()
    reset!  
  end
  
  def extract_correspondences!(input_graph)
    input_graph.each{|stmt| rule_engine << stmt}
  end
  
  def productions_for(rule_name)
    rule_engine.productions[rule_name]
  end
  
  def reset!
    @rule_engine = Wongi::Engine.create
    install_classification_ruleset! 
  end
  
  private
  
  # classifies the input and output graphs
  def install_classification_ruleset!
    rule_engine << ruleset do
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
  end
  
  # extracts the correspondences
  def install_extraction_ruleset!
  end
end
