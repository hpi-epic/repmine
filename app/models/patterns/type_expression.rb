# == Schema Information
#
# Table name: type_expressions
#
#  id                 :integer          not null, primary key
#  operator           :string(255)
#  rdf_type           :string(255)
#  pattern_element_id :integer
#  ancestry           :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class TypeExpression < ActiveRecord::Base
  attr_accessible :operator, :rdf_type
  belongs_to :pattern_element
  has_ancestry()

  def self.create_new(rdf_type, operator = nil)
    te = self.create!(:rdf_type => nil, :operator => operator)
    te.children.create!(:rdf_type => rdf_type)
    return te
  end

  def self.for_rdf_type(rdft)
    create_new(rdft, nil)
  end

  def self.for_operator(operator)
    create_new(nil, operator)
  end

  def self.for_rdf_type_and_operator(rdf_type, operator)
    create_new(rdf_type, operator)
  end

  # this is the 'simple' structure -> an empty first expression with one RDF type child
  def is_simple?
    return operator.nil? && children.size == 1 && !children.first.operator?
  end

  def resource
    return RDF::Resource.new(self.fancy_string)
  end

  def fancy_string(shorten = false)
    if operator?
      if operator == OwlClass::SET_OPS[:not]
        return str(shorten) + children.first.fancy_string(shorten)
      else
        expr = children.sort_by{|a| a.created_at}.collect{|c| c.fancy_string(shorten)}.join(operator)
        expr = "(#{expr})" if depth > 0
        return expr
      end
    else
      return rdf_type.blank? ? nil : str(shorten)
    end
  end

  def str(shorten)
    if operator?
      return operator
    else
      return shorten ? rdf_type.split("/").last.split("#").last : rdf_type
    end
  end

  def operator?
    return rdf_type.nil?
  end

end
