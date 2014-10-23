class PatternElement < ActiveRecord::Base

  # explicitly allows setting the rdf type of a node
  attr_accessible :rdf_type

  has_one :type_expression, :dependent => :destroy
  belongs_to :pattern
  after_create :build_type_expression
  
  def build_type_expression()
    self.type_expression ||= TypeExpression.create(:pattern_element => self, :rdf_type => nil)
    type_expression.children.create(:rdf_type => "")
  end
  
  def rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string
  end
  
  def short_rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string(true)
  end
  
  # if only the string is set, everything should work as normal
  def rdf_type=(str)
    if type_expression.fancy_string != str
      if type_expression.children.size == 1 && !type_expression.children.first.operator?
        type_expression.children.first.update_attributes(:rdf_type => str)
      else
        type_expression.destroy
        type_expression = TypeExpression.create(:pattern_element => self, :rdf_type => nil)
        type_expression.children.create(:rdf_type => str)
        type_expression.save
      end
    end
  end
  
  def used_concepts
    return type_expression.used_concepts
  end 
end
