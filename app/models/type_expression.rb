class TypeExpression < ActiveRecord::Base
  attr_accessible :operator, :rdf_type, :pattern_element
  belongs_to :pattern_element
  has_ancestry
  
  def resource
    # TODO: create OWL Union and so on...
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
  
  def used_concepts
    concepts = []
    concepts << rdf_type unless operator?
    children.each{|child| concepts.concat(child.used_concepts)}
    return concepts  
  end
  
  def reset!
    pattern = pattern_element.nil? ? root.pattern_element.pattern : pattern_element.pattern
    if self.created_at > pattern.updated_at
      self.destroy
    else
      self.reload
    end
  end
end
