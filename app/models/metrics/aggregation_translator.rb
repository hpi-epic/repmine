class AggregationTranslator

  attr_accessor :engine

  class NoMatchFoundError < Exception;end

  def initialize(*args)
    @engine = Wongi::Engine.create
  end

  def load_to_engine!(input_element, output_elements)
    engine << [input_element.id, "is_a", input_element.class.name]
    output_elements.each do |oe|
      engine << [oe.id, "is_a", oe.class.name]
      engine << [input_element.id, "maps_to", oe.id]
      if oe.is_a?(RelationConstraint)
        engine << [oe.id, "source", oe.source.id]
        engine << [oe.id, "target", oe.target.id]
      end
    end
  end

  def substitute
    target_nodes = []

    acs = engine.rule "substitute" do
      forall {
        has :ElIn, "is_a", :Node
        has :ElIn, "maps_to", :ElOut1
        has :ElIn, "maps_to", :ElOut2
        has :ElOut1, "is_a", "Node"
        has :ElOut2, "is_a", "AttributeConstraint"
      }
    end

    acs.tokens.each do |token|
      target_nodes << token[ :ElOut1 ]
    end

    rels = engine.rule "substitute" do
      forall {
        has :ElIn, "is_a", :Node
        has :ElIn, "maps_to", :ElOut1
        has :ElIn, "maps_to", :ElOut2
        has :ElIn, "maps_to", :ElOut3
        has :ElOut1, "source", :ElOut2
        has :ElOut1, "target", :ElOut3
      }
    end

    rels.tokens.each do |token|
      target_nodes << token[ :ElOut2 ]
    end

    raise "No unambiguous target found!" if target_nodes.size != 1
    return PatternElement.find(target_nodes.first)
  end

end