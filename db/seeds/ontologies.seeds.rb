[
  "https://seal-team.ifi.uzh.ch/seon/ontologies/general/2012/02/main.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/general/2012/02/measurement.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/general/2012/02/measurement.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/clones.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/code-flaws.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/change-couplings.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/integration-history-issues.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/integration-code-history.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/integration-history-issues-code.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-spanning/2012/02/fine-grained-changes.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-specific/2012/02/issues.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-specific/2012/02/code.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-specific/2012/02/code-metrics.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/domain-specific/2012/02/history.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/system-specific/2012/02/jira.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/system-specific/2012/02/java.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/system-specific/2012/02/bugzilla.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/nl/2012/02/annotations-nl.owl",
  "https://seal-team.ifi.uzh.ch/seon/ontologies/nl/2012/02/code-nl.owl"
].each do |ontology_url|
  Ontology.where(
    url: ontology_url, 
    prefix_url: ontology_url.gsub("https://seal-team.ifi.uzh.ch/seon/", "http://se-on.org/"),
    short_name: "Seon##{ontology_url.split("/").last}",
    group: "SEON"
  ).first_or_create  
end