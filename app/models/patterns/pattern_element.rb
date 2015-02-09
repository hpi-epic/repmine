class PatternElement < ActiveRecord::Base
  # explicitly allows setting the rdf type of a node
  attr_accessible :rdf_type

  belongs_to :pattern
  has_one :type_expression, :dependent => :destroy

  after_create :build_type_expression!

  def build_type_expression!()
    TypeExpression.for_rdf_type(self, "")
  end

  def self.for_rdf_type(rdf_type)
    pe = self.create!()
    pe.rdf_type = rdf_type
    return pe
  end

  def self.find_by_url(url)
    return self.find(url.split("/").last.to_i)
  end
  
  def ontology
    pattern.nil? ? nil : pattern.ontology 
  end

  def url
    return pattern.url + "/#{self.class.name.underscore.pluralize}/#{id}"
  end

  def rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string
  end

  def short_rdf_type
    return type_expression.nil? ? "" : type_expression.fancy_string(true)
  end

  # this method allows overwriting an existing type expression with a SIMPLE rdf type
  def rdf_type=(str)
    if type_expression.nil?
      self.type_expression = TypeExpression.for_rdf_type(self, str)
    else
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
  end

  def used_concepts
    return type_expression.used_concepts
  end

  def contains_variable?(str)
    return !str.match(/\?([A-Za-z0-9\-_]+)/).nil?
  end

  def query_variable()
    "#{self.class.name.underscore}_#{self.id}"
  end
  
  def equal_to?(other)
    raise "operation not permitted on elements of the same pattern" if self.pattern == other.pattern
    return self.class == other.class && self.rdf_type == other.rdf_type
  end
end
