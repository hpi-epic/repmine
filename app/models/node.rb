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
  
  include RdfSerialization  
    
  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end
  
  def build_type_expression()
    self.type_expression ||= TypeExpression.create(:node => self, :rdf_type => nil)
    type_expression.children.create(:rdf_type => "")
  end
  
  def rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string
  end
  
  # if only the string is set, everything should work as normal
  def rdf_type=(str)
    if type_expression.fancy_string != str
      if type_expression.children.size == 1 && !type_expression.children.first.operator?
        type_expression.children.first.update_attributes(:rdf_type => str)
      else
        type_expression.destroy
        type_expression = TypeExpression.create(:node => self, :rdf_type => nil)
        type_expression.children.create(:rdf_type => str)
        type_expression.save
      end
    end
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
    [
      [resource, Vocabularies::GraphPattern.nodeType, type_expression.resource]
    ]
  end
    
  def rdf_types
    [Vocabularies::GraphPattern.PatternElement, Vocabularies::GraphPattern.Node]
  end
end
