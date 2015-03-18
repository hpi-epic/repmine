RepMine
=======

This project distributes the problem of matching two ontologies on query level. To this end, the following workflow is implemented:

* Creation of Graphical Representations of SPARQL, Cypher, and SQL queries
* Automated ontology matching between the source and the target ontology using AML https://github.com/AgreementMakerLight
* Manual translation of remaining query elements with simultaneous extraction of ontology correspondences 

Currently Supported
===
* Data Sources
  * RDBMS: Postgresql and Mysql
  * GraphDBs: Neo4j and RDF Triple Stores with OWL ontologies
* Query Languages
  * SQL
  * Cypher
  * SPARQL 1.1
* Service Integration
  * WE-BPEL services
  * Ruby Scripts operating on properties as input elements

Contact
===
For more information about the project, please contact thomas.kowark@hpi.de
