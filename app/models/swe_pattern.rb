class SwePattern < ActiveRecord::Base
  # attributes
  attr_accessible :name, :description
  
  # relations
  has_and_belongs_to_many :patterns
  
  # validations
  validates :name, :presence => true
  validates :description, :presence => true
end
