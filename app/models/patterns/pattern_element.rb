class PatternElement < ActiveRecord::Base
  # explicitly allows setting the rdf type of an element and the ontology
  attr_accessible :rdf_type, :ontology_id, :name, :pattern_id

  # allows to access the rdf node, in case this pattern stems from an rdf graph
  attr_accessor :rdf_node

  belongs_to :pattern, :class_name => "Measurable"
  belongs_to :ontology

  has_many :matches, :foreign_key => :matched_element_id, :class_name => "PatternElementMatch", :dependent => :destroy
  has_many :matchings, :foreign_key => :matching_element_id, :class_name => "PatternElementMatch", :dependent => :destroy
  has_many :matched_elements, :through => :matchings
  has_many :matching_elements, :through => :matches

  before_destroy :invalidate_translations, prepend: true
  after_save :invalidate_translations_if_dirty

  after_create :set_name
  validates :name, :uniqueness => {scope: :pattern_id}, length: {minimum: 3}, unless: :new_record?

  include RdfSerialization

  class ComparisonError < Error
  end

  def invalidate_translations
    # destroy all elements that we have been translated to
    matching_elements.each{|me| me.destroy}
    # and all relations where we are the matching elements
    matchings.each{|match| match.destroy}
  end

  def invalidate_translations_if_dirty
    invalidate_translations if !changes["rdf_type"].nil? && !changes["rdf_type"][0].nil?
  end

  def set_name
    update_attributes(name: "#{type || self.class.name} #{self.id}") if self.name.blank?
  end

  def url
    pattern.url + "/#{self.class.name.underscore.pluralize}/#{id}"
  end

  def short_rdf_type
    rdf_type.split("/").last.split("#").last
  end

  def qualified_type()
    ontology.short_name + "#" + short_rdf_type
  end

  def type_resource
    RDF::Resource.new(rdf_type)
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
      [resource, Vocabularies::GraphPattern.elementType, RDF::Resource.new(rdf_type)]
    ]
  end

  def graph_strings(elements = [])
    []
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

  def rebuild!(queryable)
    rebuild_element_type!(queryable, self.rdf_node)
    rebuild_element_properties!(queryable, self.rdf_node)
  end

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