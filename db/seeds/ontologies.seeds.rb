puts "Creating SEON ontology"
Ontology.where(
  url: "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/seon.owl",
  short_name: "Seon#seon.owl",
  group: "Software Repositories"
).first_or_create

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
  "http://oaei.ontologymatching.org/2014/conference/data/Cocus.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/paperdyne.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/edas.owl",
  "http://oaei.ontologymatching.org/2014/conference/data/MyReview.owl",
  #"http://oaei.ontologymatching.org/2014/conference/data/linklings.owl"
].each do |ontology_url|
  puts "Creating #{ontology_url}"
  Ontology.where(
    url: ontology_url,
    short_name: "Conference##{ontology_url.split("/").last}",
    group: "OAEI Conference"
  ).first_or_create
end
