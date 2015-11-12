puts "Creating SEON ontology"
Ontology.where(
  url: "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/seon.owl",
  short_name: "seon.owl",
  group: "Software Repositories"
).first_or_create

# Conference Ontologies (OAEI)
#[
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/cmt.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/Cocus.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/confOf.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/Conference.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/confious.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/crs_dr.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/edas.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/ekaw.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/iasted.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/MICRO.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/MyReview.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/OpenConf.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/PCS.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/paperdyne.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/conference/sigkdd.owl"
#].each do |ontology_url|
#  puts "Creating #{ontology_url}"
#  Ontology.where(
#    url: ontology_url,
#    short_name: "Conference##{ontology_url.split("/").last}",
#    group: "OAEI Conference"
#  ).first_or_create
#end

# Anatomy Ontologies (OAEI)
#[
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/anatomy/mouse.owl",
#  "https://dl.dropboxusercontent.com/u/1622986/ontologies/anatomy/human.owl"
#].each do |ontology_url|
#  puts "Creating #{ontology_url}"
#  Ontology.where(
#    url: ontology_url,
#    short_name: "Anatomy##{ontology_url.split("/").last}",
#    group: "OAEI Anatomy"
#  ).first_or_create
#end