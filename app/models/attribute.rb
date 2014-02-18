class Attribute
  attr_accessor :name, :type, :domain
  
  def initialize(name, type, domain)
    @name = name
    @type = type
    @domain = domain
  end
end
