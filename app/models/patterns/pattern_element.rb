class PatternElement < ActiveRecord::Base
  # explicitly allows setting the rdf type of an element and the ontology
  attr_accessible :rdf_type, :ontology_id
  
  # allows to access the rdf node, in case this pattern stems from an rdf graph
  attr_accessor :rdf_node
  
  belongs_to :pattern
  belongs_to :ontology
  
  has_many :matches, :foreign_key => :matched_element_id, :class_name => "PatternElementMatch", :dependent => :destroy
  has_many :matchings, :foreign_key => :matching_element_id, :class_name => "PatternElementMatch", :dependent => :destroy
  has_many :matched_elements, :through => :matchings, :dependent => :destroy
  has_many :matching_elements, :through => :matches, :dependent => :destroy
  
  has_one :type_expression, :dependent => :destroy
  include RdfSerialization
  
  class ComparisonError < Error
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
      self.type_expression = TypeExpression.for_rdf_type(str)
    else
      # we only need to overwrite if the strings differ...
      if type_expression.fancy_string != str
        if type_expression.is_simple?
          type_expression.children.first.update_attributes(:rdf_type => str)
        else
          type_expression.destroy
          self.type_expression = TypeExpression.for_rdf_type(str)
        end
      end
    end
  end
  
  def equal_to?(other)
    raise ComparisonError.new("operation not permitted on elements of the same pattern") if self.pattern == other.pattern
    return self.class == other.class && self.rdf_type == other.rdf_type
  end

  # Query stuff
  def contains_variable?(str)
    return !str.match(/\?([A-Za-z0-9\-_]+)/).nil?
  end
  
  def is_variable?
    return false
  end
  
  # RDF Serialization
  def rdf_statements
    return [
      [resource, Vocabularies::GraphPattern.belongsTo, pattern.resource],
      [resource, Vocabularies::GraphPattern.elementType, type_expression.resource]
    ]
  end
  
  def rdf_types
    [Vocabularies::GraphPattern.PatternElement]
  end
  
  def rdf_mappings
    {}
  end
  
  def label_for_type
    ontology.label_for_resource(rdf_type)
  end
  
  def correspondences_to(ont)
    return OntologyMatcher.new(ontology, ont).correspondences_for_concept(rdf_type)
  end
  
  def rebuild!(queryable)
    rebuild_element_type!(queryable, self.rdf_node)
    rebuild_element_properties!(queryable, self.rdf_node)
  end
  
  def variable_name
    return "#{self.class.name.underscore}_#{id}"
  end
  
  def speaking_name
    str = short_rdf_type
    if pattern.pattern_elements.any?{|pe| pe.id != id && pe.rdf_type == rdf_type}
      str += id.to_s
    end
    return str
  end
  
  # TODO: also become able to rebuild complex expressions (universal, someOf, and schmutz like that)  
  # P.S.: that is also why this is currently a separate method...
  def rebuild_element_type!(queryable, node)
    queryable.query(:subject => node, :predicate => Vocabularies::GraphPattern.elementType) do |res|
      self.rdf_type = res.object.to_s
    end
  end
  
  def rebuild_element_properties!(queryable, node)
    rdf_mappings.each_pair do |property, mapping|
      queryable.query(:subject => node, :predicate => property) do |res|
        if mapping[:collection]
          connected_element = pattern.pattern_elements.find{|el| el.rdf_node == res.object}
          self.send(mapping[:property]).send(:<< , connected_element) unless connected_element.nil?
        else        
          value = mapping[:literal] ? res.object.object : pattern.pattern_elements.find{|pe| pe.rdf_node == res.object}
          self.send("#{mapping[:property]}=".to_sym, value) unless value.nil?
        end
      end
    end
  end
end
