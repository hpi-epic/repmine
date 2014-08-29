# SEON ontologies
[
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/main.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/measurement.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/measurement.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/clones.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/code-flaws.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/change-couplings.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/integration-history-issues.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/integration-code-history.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/integration-history-issues-code.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/fine-grained-changes.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/issues.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/code.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/code-metrics.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/history.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/jira.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/java.owl",
  "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/bugzilla.owl"
].each do |ontology_url|
  Ontology.where(
    url: ontology_url, 
    short_name: "Seon##{ontology_url.split("/").last}",
    group: "SEON"
  ).first_or_create
end

# Conference Ontologies (OAEI)
[
  "http://oaei.ontologymatching.org/2014/conference/data/ekaw.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/Conference.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/sigkdd.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/iasted.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/MICRO.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/confious.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/PCS.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/OpenConf.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/confOf.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/crs_dr.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/cmt.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/cocus.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/paperdyne.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/edas.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/MyReview.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/linklings.owl"
].each do |ontology_url|
  Ontology.where(
    url: ontology_url, 
    short_name: "Conference##{ontology_url.split("/").last}",
    group: "OAEI Conference"
  ).first_or_create
end