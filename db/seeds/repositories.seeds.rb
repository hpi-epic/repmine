#puts "Creating Enterprise Github neo4j repository"
#egh = Neo4jRepository.where(
#  name: "Enterprise Github",
#  host: "192.168.30.196",
#  port: 7474,
#  description: "A neo4j repository that contains enterprise github data."
#).first_or_create
#egh.analyze_repository

puts "Creating SWT2 Github neo4j repository"
gh = Neo4jRepository.where(
  name: "SWT2 Github",
  host: "192.168.30.196",
  port: 7478,
  description: "A neo4j repository that contains github data."
).first_or_create
#gh.analyze_repository

puts "Creating SEON Repository"
seon = RdfRepository.where(
  name: "SWT2 Seon Data",
  host: "172.16.30.252",
  ontology_url: "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/seon.owl",
  port: 10035,
  db_name: "repositories/seon_data",
  db_username: "semanticQuark",
  db_password: "semanticQuark"
).first_or_create