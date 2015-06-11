# encoding: utf-8
# == Schema Information
#
# Table name: pattern_elements
#
#  id              :integer          not null, primary key
#  type            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pattern_id      :integer
#  node_id         :integer
#  value           :string(255)
#  operator        :string(255)
#  min_cardinality :string(255)
#  max_cardinality :string(255)
#  min_path_length :string(255)
#  max_path_length :string(255)
#  source_id       :integer
#  target_id       :integer
#  x               :integer          default(0)
#  y               :integer          default(0)
#  is_group        :boolean          default(FALSE)
#

#!/bin/env ruby

class Node < PatternElement
  attr_accessible :x, :y, :is_group
  has_many :source_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "source_id", :dependent => :destroy
  has_many :target_relation_constraints, :class_name => "RelationConstraint", :foreign_key => "target_id", :dependent => :destroy
  has_many :attribute_constraints, :dependent => :destroy
  validates :ontology, :presence => true

  def rdf_mappings
    super.merge({
      Vocabularies::GraphPattern.attributeConstraint => {:property => :attribute_constraints, :collection => true},
      Vocabularies::GraphPattern.outgoingRelation => {:property => :source_relation_constraints, :collection => true},
      Vocabularies::GraphPattern.incomingRelation => {:property => :target_relation_constraints, :collection => true}
    })
  end

  def query_variable()
    return rdf_type.split("/").last.downcase + self.id.to_s
  end
  
  def pretty_string
    "#{type_expression.fancy_string(true)}"
  end

  def rdf_statements
    stmts = super
    
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
  
  def type_hierarchy
    return ontology.type_hierarchy
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
