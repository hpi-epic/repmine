class ConnectionFinder

  attr_accessor :engine

  class NoMatchFoundError < Exception;end

  def initialize(*args)
    @engine = Wongi::Engine.create
  end

  def load_to_engine!(mappings, original_pattern)
    load_mappings_to_engine!(mappings)
    load_pattern_to_engine!(original_pattern)
  end

  def load_pattern_to_engine!(pattern)
    pattern.attribute_constraints.each do |ac|
      engine << [ac.id, "node", ac.node_id]
    end

    pattern.relation_constraints.each do |rc|
      engine << [rc.id, "source", rc.source_id]
      engine << [rc.id, "target", rc.target_id]
    end
  end

  def load_mappings_to_engine!(mappings)
    mappings.each_pair do |originals, targets|
      originals.each do |original_id|
        targets.each do |target|
          engine << [original_id, "maps_to", target.id]
          engine << [target.id, "is_a", target.class.name]
        end
      end
    end
  end

  def node_for_ac(ac)
    process_ids(target_node_ids(ac.id))
  end

  def target_node_ids(ac_id)
    target_nodes = []

    targets = engine.rule "attribute_constraint" do
      forall {
        has :AcIn, "node", :Node
        has :AcIn, "maps_to", ac_id
        has :Node, "maps_to", :TargetNode
        has :TargetNode, "is_a", "Node"
      }
    end

    targets.tokens.each do |token|
      target_nodes << token[ :TargetNode ]
    end

    return target_nodes
  end

  def source_for_rc(rc)
    process_ids(get_relation_node_ids(rc.id, "source"))
  end

  def target_for_rc(rc)
    process_ids(get_relation_node_ids(rc.id, "target"))
  end

  def get_relation_node_ids(rc_id, direction)
    target_nodes = []

    targets = engine.rule "relation_#{direction}" do
      forall {
        has :RelIn, direction, :Node
        has :RelIn, "maps_to", rc_id
        has :Node, "maps_to", :TargetNode
        has :TargetNode, "is_a", "Node"
      }
    end

    targets.tokens.each do |token|
      target_nodes << token[ :TargetNode ]
    end

    return target_nodes
  end

  def process_ids(element_ids)
    if element_ids.size == 1
      return PatternElement.find(element_ids.first)
    elsif element_ids.empty?
      return nil
    else
      # TODO: if we have mutliple ones, we could just as well look whether one is more fitting ... domain and stuff
      raise NoMatchFoundError.new("Could not determine exactly one fitting node. #{element_ids} would work.")
    end
  end

end