#!/bin/env ruby
# encoding: utf-8

class Node < ActiveRecord::Base
  attr_accessible :rdf_type, :x, :y

  belongs_to :query
  has_many :query_relation_constraints
  has_many :query_attribute_constraints, :dependent => :destroy
  
  def start_info(uri=nil)
    start = query_variable + "="
    start += if uri.nil?
      "node:node_auto_index(`#{Graph::TYPE_FIELD}`=\"" + rdf_type + "\")"
    else
      "node:node_uri_index(resource_uri=\"" + uri + "\")"
    end
    return start
  end
  
  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end
  
  def cypher_constraints(graph)
    constraints = []
    type_constraints = ["#{query_variable}.`#{Graph::TYPE_FIELD}` = \"#{rdf_type}\""]
    types = graph.get_all_types_fast()
    types[rdf_type][:subclasses].each_pair do |subcl, name|
      type_constraints << ["#{query_variable}.`#{Graph::TYPE_FIELD}` = \"#{subcl}\""]
    end
    constraints << ["(" + type_constraints.join(" OR ") + ")"]
    return constraints.concat(query_attribute_constraints.collect{|qac| qac.to_cypher}).join(" AND ")
  end
  
  def rdf_statements
    return [
      
    ]
  end
end
