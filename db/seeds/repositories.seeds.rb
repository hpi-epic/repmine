puts "Creating local neo4j repository"
Neo4jRepository.where(
  name: "Github Data",
  host: "localhost",
  port: 7474,
  description: "A local neo4j repository that contains github data."
).first_or_create