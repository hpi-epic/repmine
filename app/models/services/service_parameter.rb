class ServiceParameter < ActiveRecord::Base
  belongs_to :external_service
  as_enum :datatype, string: 1, integer: 2, file: 3, boolean: 4
  attr_accessible :name, :datatype, :is_collection
end
