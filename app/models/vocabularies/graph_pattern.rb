module Vocabularies
  class GraphPattern < RDF::StrictVocabulary("http://hpi.de/ontologies/graph_pattern/")
    # basic classes of the graph
    term :GraphPattern,
      comment: %(Basically just a graph).freeze,
      label: "GraphPattern".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :PatternElement,
      comment: %(An element within a graph).freeze,
      label: "PatternElement".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :Node,
      comment: %(A node within a graph).freeze,
      label: "Node".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      :subClassOf => %(graphpattern:PatternElement).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :RelationConstraint,
      comment: %(A relation within a graph).freeze,
      label: "RelationConstraint".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      :subClassOf => %(graphpattern:PatternElement).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
    term :AttributeConstraint,
      comment: %(A relation within a graph).freeze,
      label: "AttributeConstraint".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      :subClassOf => %(graphpattern:PatternElement).freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze]
  
    # properties - general
    property :belongsTo,
      comment: %(A pattern element belongs to a pattern.).freeze,
      domain: "graphpattern:PatternElement".freeze,
      label: "belongsTo".freeze,
      range: "graphpattern:GraphPattern".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze,
      "owl:inverseOf" => %(graphpattern:contains).freeze

    property :contains,
      comment: %(A pattern contains pattern elements.).freeze,
      domain: "graphpattern:GraphPattern".freeze,
      label: "contains".freeze,
      range: "graphpattern:PatternElementGraphPattern".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze,
      "owl:inverseOf" => %(graphpattern:belongsTo).freeze    
  
    # properties - node
    property :nodeType,
      comment: %(The type or complex expression (unionOf, etc.) a node can have.).freeze,
      domain: "graphpattern:Node".freeze,
      label: "node type".freeze,
      range: "owl:Class".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze
    property :outgoingRelation,
      comment: %(links a node to an outgoing relation.).freeze,
      domain: "graphpattern:Node".freeze,
      label: "outgoing relation".freeze,
      range: "graphpattern:RelationConstraint".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze,
      "owl:inverseOf" => %(graphpattern:incomingRelation).freeze
    property :incomingRelation,
      comment: %(links a node to an incoming relation.).freeze,
      domain: "graphpattern:Node".freeze,
      label: "incoming relation".freeze,
      range: "graphpattern:RelationConstraint".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze,
      "owl:inverseOf" => %(graphpattern:outgoingRelation).freeze
    property :attributeConstraint,
      comment: %(links a node to a datatype attribute constraint.).freeze,
      domain: "graphpattern:Node".freeze,
      label: "attribute constraint".freeze,
      range: "graphpattern:AttributeConstraint".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze
    
    # properties - relation constraint    
    property :relationType,
      comment: %(The type or complex expression (unionOf, etc.) a relation can have.).freeze,
      domain: "graphpattern:RelationConstraint".freeze,
      label: "relation type".freeze,
      range: "owl:ObjectProperty".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze
    
    # properties - attribute constraint
    property :attributeType,
      comment: %(The type or complex expression (unionOf, etc.) a relation can have.).freeze,
      domain: "graphpattern:AttributeConstraint".freeze,
      label: "attribute type".freeze,
      range: "owl:DatatypeProperty".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:ObjectProperty".freeze
    
    property :attributeOperator,
      comment: %(The comparison operator used in the query.).freeze,
      domain: "graphpattern:AttributeConstraint".freeze,
      label: "relation type".freeze,
      range: "xsd:string".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:DatatypeProperty".freeze
    
    property :attributeValue,
      comment: %(The literal value to compare with operator used in the query.).freeze,
      domain: "graphpattern:AttributeConstraint".freeze,
      label: "attribute value".freeze,
      range: "xsd:Literal".freeze,
      "rdfs:isDefinedBy" => %(graphpattern:).freeze,
      type: "owl:DatatypeProperty".freeze    
    
    # TODO: all the cardinality stuff
  end        
end