class CorrespondenceExtractor
  attr_accessor :rule_engine
  
  def initialize()
    @rule_engine = Wongi::Engine.create
  end
  
  def extract_correspondences(input_graph)
    input_graph.each{|stmt| rule_engine << stmt}
    rule_engine << classification_ruleset
  end
  
  # classifies the input and output graphs
  def classification_ruleset
    ruleset do 
      rule("simple graph") do
        forall {
          has(:graph, Vocabularies::GraphPattern.contains, :graph_element)
          neg {
            has(:graph, Vocabularies::GraphPattern.contains, :different_element)
            diff(:graph_element, :different_element)
          }
        }
      end
    end
  end
  
  # extracts the correspondences
  def extraction_ruleset
    ruleset do
      rule("1:1") do
        forall {
        }
      end
      rule("PC") do
        
      end
    end
  end
end
