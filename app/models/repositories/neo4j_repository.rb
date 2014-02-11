#!/bin/env ruby
# encoding: utf-8

class Neo4jRepository < Repository
  
  def self.model_name
    return Repository.model_name
  end

end