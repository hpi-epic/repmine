#!/bin/env ruby
# encoding: utf-8

class Node < ActiveRecord::Base
  attr_accessible :rdf_type, :x, :y

  belongs_to :pattern
  has_many :relation_constraints, :dependent => :destroy
  has_many :attribute_constraints, :dependent => :destroy
  
  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end
    
  def possible_relations_to(target_node)
    return pattern.possible_relations_between(self.rdf_type, target_node.rdf_type, true)
  end
  
  def possible_attributes(rdf_type = nil)
    return pattern.possible_attributes_for(rdf_type || self.rdf_type)
  end
  
  def create_relation_constraint_with_target!(target)
    return RelationConstraint.from_source_to_target(self, target)
  end
  
  def rdf_statements
    return []
  end
end
