class PatternElementMatch < ActiveRecord::Base
  belongs_to :matching_element, :class_name => "PatternElement"
  belongs_to :matched_element, :class_name => "PatternElement"
end