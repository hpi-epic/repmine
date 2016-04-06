RepMine
=======

This project distributes the problem of matching two ontologies on query level. To this end, the following workflow is implemented:

* Creation of Graphical Representations of SPARQL, Cypher, and SQL queries
* Graphical definition of aggregations and calculations on the returned data
* Automated ontology matching between the source and the target ontology using AML https://github.com/AgreementMakerLight
* Guided, manual translation of remaining query elements

Currently Supported
===
* Data Sources
  * RDBMS are Mapped via d2rq (http://d2rq.org)
  * Neo4j 
  * RDF Triple Stores
* Query Languages
  * Cypher
  * SPARQL
  * SQL (via SPARQL and OWL <-> RDBMS mappings)
* Service Integration
  * REST Services with JSON responses
  * Service responses are persisted withing the source database

Contact
===
For more information about the project, please contact thomas.kowark@hpi.de
