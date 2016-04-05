puts "Creating SWT2 Github neo4j repository"
Neo4jRepository.where(
  name: "SWT2 Github",
  host: "192.168.30.233",
  port: 7478,
  description: "A neo4j repository that contains github data from the SWT2 2014/15 course."
).first_or_create

puts "Creating SEON Repository"
RdfRepository.where(
  name: "SWT2 Seon Data",
  host: "172.16.30.252",
  ontology_url: "https://dl.dropboxusercontent.com/u/1622986/ontologies/seon/seon.owl",
  port: 10035,
  db_name: "repositories/seon_data",
  db_username: "semanticQuark"
).first_or_create

puts "Creating HDB Repo"
Neo4jRepository.where(
  name: "Dev Data",
  host: "192.168.30.233",
  port: 7486,
  description: "Git data from a large company repo"
).first_or_create