class Relation
  attr_accessor :domain, :range, :name
  def initialize(name, range, domain)
    @domain = domain
    @range = range
    @name = name
  end  
end
