class Measurable < ActiveRecord::Base
  attr_accessible :name, :description, :tag_list
  acts_as_taggable_on :tags

  has_many :monitoring_tasks, :dependent => :destroy

  def run(monitoring_task)
    raise "implement 'run(monitoring_task)' in #{self.class.name}"
  end

  def executable_on?(ontology)
    raise "implement 'executable_on?' in #{self.class.name}"
  end

  def untranslated_patterns(ontology)
    raise "implement 'untranslated_patterns(ontology)' in #{self.class.name}"
  end

  def queries(monitoring_task)
    raise "implement 'queries(monitoring_task)' in #{self.class.name}"
  end

  def self.grouped(excluded_instances = [])
    measurable_groups = {}

    where(type: self.name).each do |measurable|
      next if excluded_instances.include?(measurable)
      tag_list = measurable.tag_list.empty? ? ["Uncategorized"] : measurable.tag_list
      tag_list.each do |tag|
        measurable_groups[tag] ||= []
        measurable_groups[tag] << measurable
      end
    end
    return measurable_groups
  end

  def first_untranslated_pattern(ontology)
    self
  end
end
