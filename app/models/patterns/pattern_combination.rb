class PatternCombination
  
  # constants
  OPERATORS = ["AND", "OR", "XOR"]
  
  def self.from_patterns(patterns, nodes, operator, name)
    input_names = patterns.collect{|p| p.name}
    pattern = CombinationPattern.new(:name => name.blank? ? input_names.join(" + ") : name, :description => "Combination of #{input_names.join(" and ")}")
    pattern.ontologies = patterns.collect{|p| p.ontologies}.flatten.uniq
    pattern.pattern_elements = patterns.collect{|p| p.pattern_elements}.flatten
    pattern.save
    return pattern
  end
  
end