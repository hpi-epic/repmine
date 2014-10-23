#!/bin/env ruby
# encoding: utf-8

class Node < PatternElement
  attr_accessible :x, :y
  has_many :source_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "source_id", :dependent => :destroy
  has_many :target_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "target_id", :dependent => :destroy  
  has_many :attribute_constraints, :dependent => :destroy
  
  include RdfSerialization  
    
  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end
    
  def reset!
    # remove the newly created ones
    source_relation_constraints.find(:all, :conditions => ["created_at > ?", self.pattern.updated_at]).each{|rc| rc.destroy}
    attribute_constraints.find(:all, :conditions => ["created_at > ?", self.pattern.updated_at]).each{|ac| ac.destroy}
    # and get rid of all the changed attributes n stuff
    source_relation_constraints.reload    
    attribute_constraints.reload
    source_relation_constraints.each{|rc| rc.reload}
    attribute_constraints.each{|rc| rc.reload}
    # reset the type expression
    type_expression.reset!
  end
  
  def used_concepts
    return type_expression.used_concepts + source_relation_constraints.collect{|src| src.used_concepts} + attribute_constraints.collect{|src| src.used_concepts}
  end
  
  def url
    return pattern.url + "/nodes/#{id}"
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
end
