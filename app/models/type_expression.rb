class TypeExpression < ActiveRecord::Base
  attr_accessible :operator, :rdf_type, :node
  belongs_to :node
  has_ancestry
  
  def fancy_string(shorten = false)
    if operator?
      if operator == OwlClass::SET_OPS[:not]
        return str(shorten) + children.first.fancy_string(shorten)
      else
        return children.sort_by{|a| a.created_at}.collect{|c| c.fancy_string(shorten)}.join(operator)
      end
    else
      return str(shorten)
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
    return !operator.nil?
  end
  
  def reset!
    pattern = node.nil? ? root.node.pattern : node.pattern
    if self.created_at > pattern.updated_at
      self.destroy
    else
      self.reload
    end
  end
end
