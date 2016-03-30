# encoding: utf-8
#!/bin/env ruby

class Node < PatternElement
  attr_accessible :x, :y, :is_group
  has_many :source_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "source_id", :dependent => :destroy
  has_many :target_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "target_id", :dependent => :destroy
  has_many :attribute_constraints, :dependent => :destroy
  validates :ontology, :presence => true

  def pretty_string
    "#{type_expression.fancy_string(true)}"
  end

  def rdf_mappings
    super.merge({
      Vocabularies::GraphPattern.attributeConstraint => {:property => :attribute_constraints, :collection => true},
      Vocabularies::GraphPattern.outgoingRelation => {:property => :source_relation_constraints, :collection => true},
      Vocabularies::GraphPattern.incomingRelation => {:property => :target_relation_constraints, :collection => true}
    })
  end

  def rdf_statements
    stmts = super
    attribute_constraints.each{|ac| stmts << [resource, Vocabularies::GraphPattern.attributeConstraint, ac.resource]}
    source_relation_constraints.each{|src| stmts << [resource, Vocabularies::GraphPattern.outgoingRelation, src.resource]}
    target_relation_constraints.each{|trc| stmts << [resource, Vocabularies::GraphPattern.incomingRelation, trc.resource]}
    return stmts
  end

  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.Node]
  end

  def type_hierarchy
    return ontology.type_hierarchy
  end

  def equal_to?(other)
    if super
      return check_ac_and_rc_similarity(other) && other.check_ac_and_rc_similarity(self)
    else
      return false
    end
  end

  def graph_strings(elements = [])
    if (elements & (attribute_constraints + source_relation_constraints + target_relation_constraints)).empty?
      return [rdf_type]
    else
      return []
    end
  end

  # checks whether each of our elements has exactly one twin. Does NOT check whether "other" has more elements
  def check_ac_and_rc_similarity(other)
    equal = source_relation_constraints.none?{|src| other.source_relation_constraints.select{|osrc| src.equal_to?(osrc)}.size != 1}
    equal &&= target_relation_constraints.none?{|trc| other.target_relation_constraints.select{|otrc| trc.equal_to?(otrc)}.size != 1}
    equal &&= attribute_constraints.none?{|ac| other.attribute_constraints.select{|oac| ac.equal_to?(oac)}.size != 1}
    return equal
  end

  def possible_attribute_constraints
    ontology.attributes_for(rdf_type)
  end
end
