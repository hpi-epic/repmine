class PatternElementMatch < ActiveRecord::Base
  attr_accessible :matching_element, :matched_element
  belongs_to :matching_element, :class_name => "PatternElement", :dependent => :destroy
  belongs_to :matched_element, :class_name => "PatternElement"
  belongs_to :correspondence

  # determines which groups of matches belong together
  def self.matching_groups(matching_element_ids)
    matches = self.where(matching_element_id: matching_element_ids)
    groups = {}
    matches.group_by{|el| el.matching_element}.each_pair do |matching, matches|
      matched_elements = matches.map(&:matched_element)
      groups[matched_elements] ||= []
      groups[matched_elements] << matching
    end
    return groups
  end
end
