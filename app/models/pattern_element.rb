class PatternElement < ActiveRecord::Base
  # explicitly allows setting the rdf type of a node
  attr_accessible :rdf_type

  has_one :type_expression, :dependent => :destroy
  belongs_to :pattern
  
  belongs_to :equivalent, :class_name => "PatternElement"
  has_many :equivalents, :class_name => "PatternElement", :foreign_key => "equivalent_id"
  
  after_create :build_type_expression!
  
  def build_type_expression!()
    TypeExpression.for_rdf_type(self, "")
  end
  
  def rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string
  end
  
  def short_rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string(true)
  end
  
  # this method allows overwriting an existing type expression with a SIMPLE rdf type
  def rdf_type=(str)
    # we only need to overwrite if the strings differ...
    if type_expression.fancy_string != str
      if type_expression.is_simple?
        type_expression.children.first.update_attributes(:rdf_type => str)
      else
        type_expression.destroy
        self.type_expression = TypeExpression.for_rdf_type(self, str)
      end
    end
  end
  
  def used_concepts
    return type_expression.used_concepts
  end 
end
