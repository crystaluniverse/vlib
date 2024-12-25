# Base Object and Actor Backend

This is Hero’s backend, designed around the concept of base objects and actors to enable modular, domain-specific operations.

## Base Object

Base objects are digital representations of real-world entities. Examples include projects, publications, books, stories (agile), and calendar events. These objects:
	•	Serve as the primary data units that actors operate on.
	•	Contain indexable fields for efficient retrieval.
	•	Share a common base class with attributes like:
	•	Name: The object’s identifier.
	•	Description: A brief summary of the object.
	•	Remarks: A list of additional notes or metadata.

Base objects are stored, indexed, retrieved, and updated using OSIS (Object Storage and Indexing System).

## Actor

Actors are domain-specific operation handlers that work on base objects. For instance, a Project Manager Actor might manage operations on stories, sprints, or projects.

Key Features of Actors:
	•	Domain-Specific Languages (DSLs): Actor methods form intuitive, logical DSLs for interacting with base objects.
	•	Specification-Driven:
	•	Actors are generated from specifications.
	•	Code written for actor methods can be parsed back into specifications.
	•	Code Generation: Specifications enable automated boilerplate code generation, reducing manual effort.

## Modules

### OSIS: Object Storage and Indexing System

OSIS is a module designed for efficient storage and indexing of root objects based on specific fields. It enables seamless management of data across various backends, with built-in support for field-based filtering and searching.

#### Key Components

**Indexer:**
* Creates and manages SQL tables based on base object specifications.
* Enables indexing of specific fields, making them searchable and filterable.
  
**Storer**:
* Handles actual data storage in different databases.
* Supports diverse encoding and encryption methods for secure data management.

By integrating OSIS, the backend achieves both high-performance data querying and flexible, secure storage solutions.

### Example Actor Module

The Example Actor module is a reference and testable example of a generated actor within Baobab. It demonstrates the structure of actor modules generated from specifications and can also be parsed back into specifications. This module serves two key purposes:

1.	Acts as a reference for developers working on Baobab to understand and program against actor specifications.
2.	Provides a compilable, generatable module for testing and validating Baobab’s code generation tools.