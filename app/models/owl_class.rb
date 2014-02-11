class OwlClass
  attr_accessor :subclasses, :name, :outgoing_relations, :uri
  
  def initialize(uri)
    @subclasses = Set.new
    @uri = uri
    @name = uri.split("/").last
  end
  
end