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

  def first_unexecutable_pattern(repository)
    return self
  end

  def translated_to(repository)
    if translation_unnecessary?(repository)
      return self
    else
      return TranslationPattern.existing_translation_pattern(self, [repository.ontology])
    end
  end
end
