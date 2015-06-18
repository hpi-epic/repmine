puts "Creating Enterprise Github neo4j repository"
Neo4jRepository.where(
  name: "Enterprise Github",
  host: "192.168.30.196",
  port: 7474,
  description: "A neo4j repository that contains enterprise github data."
).first_or_create

puts "Creating SWT2 Github neo4j repository"
Neo4jRepository.where(
  name: "SWT2 Github",
  host: "192.168.30.196",
  port: 7478,
  description: "A neo4j repository that contains github data."
).first_or_create