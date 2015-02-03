#!/bin/env ruby
# encoding: utf-8

class Node < PatternElement
  attr_accessible :x, :y, :is_group
  has_many :source_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "source_id", :dependent => :destroy
  has_many :target_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "target_id", :dependent => :destroy
  has_many :attribute_constraints, :dependent => :destroy

  include RdfSerialization

  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end

  def used_concepts
    return type_expression.used_concepts + source_relation_constraints.collect{|src| src.used_concepts} + attribute_constraints.collect{|src| src.used_concepts}
  end

  def rdf_statements
    stmts = [
      [resource, Vocabularies::GraphPattern.elementType, type_expression.resource],
      [resource, Vocabularies::GraphPattern.belongsTo, pattern.resource]
    ]

    attribute_constraints.each do |ac|
      stmts << [resource, Vocabularies::GraphPattern.attributeConstraint, ac.resource]
      stmts.concat(ac.rdf)
    end

    source_relation_constraints.each do |src|
      stmts << [resource, Vocabularies::GraphPattern.outgoingRelation, src.resource]
      stmts.concat(src.rdf)
    end

    target_relation_constraints.each{|trc| stmts << [resource, Vocabularies::GraphPattern.incomingRelation, trc.resource]}
    return stmts
  end

  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.Node]
  end
  
  def equal_to?(other)
    if super
      # check cardinalities of all the relations
      return check_ac_and_rc_similarity(other) && other.check_ac_and_rc_similarity(self)
    else
      return false
    end
  end
  
  def check_ac_and_rc_similarity(other)
    equal = source_relation_constraints.size == other.source_relation_constraints.size
    equal &&= target_relation_constraints.size == other.target_relation_constraints.size
    equal &&= attribute_constraints.size == other.attribute_constraints.size
    # then check if each rc and ac has exactly one twin
    equal &&= source_relation_constraints.find{|src| other.source_relation_constraints.select{|osrc| src.equal_to?(osrc)}.size != 1}.nil?
    equal &&= target_relation_constraints.find{|trc| other.target_relation_constraints.select{|otrc| trc.equal_to?(otrc)}.size != 1}.nil?      
    equal &&= attribute_constraints.find{|ac| other.attribute_constraints.select{|oac| ac.equal_to?(oac)}.size != 1}.nil?
    return equal
  end
end