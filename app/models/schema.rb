class Schema
  
  attr_accessor :classes
  
  def initialize(*args)
    @classes = Set.new()
  end
  
end
