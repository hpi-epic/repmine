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

class PatternElement < ActiveRecord::Base
  # explicitly allows setting the rdf type of a node
  attr_accessible :rdf_type
  
  # allows to access the rdf node, in case this pattern stems from an rdf graph
  attr_accessor :rdf_node

  belongs_to :pattern
  has_one :type_expression, :dependent => :destroy

  after_create :build_type_expression!
  
  include RdfSerialization

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
  
  def equal_to?(other)
    raise "operation not permitted on elements of the same pattern" if self.pattern == other.pattern
    return self.class == other.class && self.rdf_type == other.rdf_type
  end

  # Query stuff
  def contains_variable?(str)
    return !str.match(/\?([A-Za-z0-9\-_]+)/).nil?
  end

  def query_variable()
    "#{self.class.name.underscore}_#{self.id}"
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
  
  def rebuild!(graph)
    rebuild_element_type!(graph, self.rdf_node)
    rebuild_element_properties!(graph, self.rdf_node)
  end
  
  # TODO: also become able to rebuild complex expressions (universal, someOf, and schmutz like that)  
  # P.S.: that is also why this is currently a separate method...
  def rebuild_element_type!(graph, node)
    RDF::Query.execute(graph) do
      pattern [node, Vocabularies::GraphPattern.elementType, :element_type]
    end.each do |res|
      self.rdf_type = res[:element_type].to_s
    end
  end
  
  def rebuild_element_properties!(graph, node)
    rdf_mappings.each_pair do |property, mapping|
      RDF::Query.execute(graph) do
        pattern([node, property, :prop])
      end.each do |res|
        if mapping[:collection]
          connected_element = pattern.pattern_elements.find{|el| el.rdf_node == res[:prop]}
          self.send(mapping[:property]).send(:<< , connected_element) unless connected_element.nil?
        else
          value = mapping[:literal] ? res[:prop].object : pattern.pattern_elements.find{|pe| pe.rdf_node == res[:prop]}
          self.send("#{mapping[:property]}=".to_sym, value) unless value.nil?
        end
      end
    end
  end  
end