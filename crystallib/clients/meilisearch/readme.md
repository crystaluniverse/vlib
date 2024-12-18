## Meilisearch V Client

This is a simple V client for interacting with a [self-hosted Meilisearch instance](https://www.meilisearch.com/docs/learn/self_hosted/getting_started_with_self_hosted_meilisearch?utm_campaign=oss&utm_medium=home-page&utm_source=docs#setup-and-installation), enabling you to perform operations such as adding, retrieving, deleting, and searching documents within indexes.

### Getting Started with Self-Hosted Meilisearch

To use this V client, ensure you have a **self-hosted Meilisearch instance installed and running**. 

This quick start will walk you through installing Meilisearch, adding documents, and performing your first search.

#### Requirements

To follow this setup, you will need `curl` installed

### Setup and Installation

To install Meilisearch locally, run the following command:

```bash
# Install Meilisearch
curl -L https://install.meilisearch.com | sh
```

### Running Meilisearch

Start Meilisearch with the following command, replacing `"aSampleMasterKey"` with your preferred master key:

```bash
# Launch Meilisearch
meilisearch --master-key="aSampleMasterKey"
```
---

### Running the V Client Tests

This client includes various test cases that demonstrate common operations in Meilisearch, such as creating indexes, adding documents, retrieving documents, deleting documents, and performing searches. To run the tests, you can use the following commands:

```bash
# Run document-related tests
v -enable-globals -stats crystallib/clients/meilisearch/document_test.v

# Run index-related tests
v -enable-globals -stats crystallib/clients/meilisearch/index_test.v
```

### Example: Getting Meilisearch Server Version

Here is a quick example of how to retrieve the Meilisearch server version using this V client:

```v
import freeflowuniverse.crystallib.clients.meilisearch

mut client := meilisearch.get() or { panic(err) }
version := client.version() or { panic(err) }
println('Meilisearch version: $version')

```

This example connects to your local Meilisearch instance and prints the server version to verify your setup is correct.
