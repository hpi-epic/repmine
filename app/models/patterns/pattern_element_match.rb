class PatternElementMatch < ActiveRecord::Base
  attr_accessible :matching_element, :matched_element
  belongs_to :matching_element, :class_name => "PatternElement"
  belongs_to :matched_element, :class_name => "PatternElement"
  belongs_to :correspondence
end
