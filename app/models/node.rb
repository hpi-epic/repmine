#!/bin/env ruby
# encoding: utf-8

class Node < ActiveRecord::Base
  attr_accessible :x, :y
  has_one :type_expression, :dependent => :destroy

  belongs_to :pattern
  has_many :source_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "source_id", :dependent => :destroy
  has_many :target_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "target_id", :dependent => :destroy  
  has_many :attribute_constraints, :dependent => :destroy
  
  after_create :build_type_expression
    
  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end
  
  def rdf_statements
    return []
  end
  
  def build_type_expression
    self.type_expression ||= TypeExpression.new(:node => self)
  end
  
  def rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string
  end
  
  # if only the string is set, everything should work as normal
  def rdf_type=(str)
    type_expression.root.rdf_type = str
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
    concepts = Set.new()
    remove_them = OwlClass::SET_OPS.values + ["(",")"]
    remove_us_regex = Regex.new(remove_them.join("|"))
    nodes.each{|op| concepts.concat(rdf_type.gsub(remove_us_regex, " "))}
    attribute_constraints.each{|ac| concepts.concat()}
  end
end
