class Measurable < ActiveRecord::Base
  attr_accessible :name, :description, :tag_list  
  acts_as_taggable_on :tags
  
  def run_on_repository(repository)
    raise "implement 'run_on_repository' in #{self.class.name}"
  end
  
  def executable_on?(repository)
    raise "implement 'executable_on?' in #{self.class.name}"
  end
  
  def self.grouped(nice_display = false)
    measurable_groups = {}
    where(:type => self.name).each do |measurable|
      tag_list = measurable.tag_list.empty? ? ["Uncategorized"] : measurable.tag_list
      tag_list.each do |tag|
        measurable_groups[tag] ||= []
        if nice_display
          measurable_groups[tag] << [measurable.name, measurable.id] 
        else
          measurable_groups[tag] << measurable
        end
      end
    end
    return measurable_groups
  end
end
