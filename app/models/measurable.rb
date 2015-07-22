class Measurable < ActiveRecord::Base
  attr_accessible :name, :description, :tag_list  
  acts_as_taggable_on :tags
  
  has_many :monitoring_tasks, :dependent => :destroy
  
  def run_on_repository(repository)
    raise "implement 'run_on_repository' in #{self.class.name}"
  end
  
  def executable_on?(repository)
    raise "implement 'executable_on?' in #{self.class.name}"
  end
  
  def self.grouped(nice_display = false, include_class = false, exceptions = [])
    measurable_groups = {}
    where(:type => self.name).each do |measurable|
      next if exceptions.include?(measurable)
      tag_list = measurable.tag_list.empty? ? ["Uncategorized"] : measurable.tag_list
      tag_list.each do |tag|
        measurable_groups[tag] ||= []
        if nice_display
          measurable_groups[tag] << [(measurable.name || "#{measurable.id}") + "#{include_class ? " (#{self.name})" : ""}", measurable.id]
        else
          measurable_groups[tag] << measurable
        end
      end
    end
    return measurable_groups
  end
  
  def first_unexecutable_pattern(repository)
    return self
  end
end
