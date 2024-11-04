# Meilisearch Client Implementation

## Overview

This project implements a client for Meilisearch, a powerful, fast, and open-source search engine. Meilisearch provides a RESTful search API that delivers relevant results with typo tolerance, filters, and excellent search-as-you-type functionality.

### What is Meilisearch?

Meilisearch is designed to provide:
- Lightning-fast search (response times < 50ms)
- Typo tolerance
- Full-text search
- Phrase search
- Filtering and faceting
- Sorting
- Custom ranking rules
- RESTful API
- Search-as-you-type experience
- Support for multiple languages
- Easy integration with various platforms

## Implementation Goals

Our client implementation aims to:
1. Provide a simple, intuitive interface to interact with Meilisearch
2. Support all core Meilisearch operations:
   - Document management (add, update, delete)
   - Search functionality
   - Index management
   - Settings configuration
   - Health and stats monitoring
3. Handle authentication and secure communication
4. Implement proper error handling and retries
5. Provide async/await support for better performance

## Requirements

To implement the Meilisearch client, we need:

1. Meilisearch server:
   ```bash
   # Using Docker
   docker run -p 7700:7700 getmeili/meilisearch:latest
   ```

2. Dependencies:
   - HTTP client for API communication
   - JSON serialization/deserialization
   - Error handling utilities
   - Testing framework

## Implementation Steps

1. **Core Client Setup**
   - Implement base client structure
   - Add configuration handling
   - Setup HTTP client with proper headers and authentication

2. **Index Operations**
   - Create/delete indexes
   - Get index information
   - List all indexes
   - Update index settings

3. **Document Operations**
   - Add/update documents
   - Delete documents
   - Get documents
   - Batch operations support

4. **Search Implementation**
   - Basic search functionality
   - Advanced search with filters
   - Search parameter handling
   - Result pagination

5. **Settings Management**
   - Synonyms
   - Stop words
   - Ranking rules
   - Distinct attributes
   - Searchable attributes
   - Displayed attributes

6. **Error Handling**
   - Custom error types
   - Proper error messages
   - Retry mechanisms
   - Timeout handling

7. **Testing**
   - Unit tests
   - Integration tests
   - Performance tests
   - Edge case handling

## API Structure

The client will expose the following main interfaces:

```rust
// Example API structure (subject to change)
pub struct MeiliClient {
    config: ClientConfig,
    http_client: HttpClient,
}

impl MeiliClient {
    // Core operations
    pub async fn health() -> Result<Health>;
    pub async fn version() -> Result<Version>;
    
    // Index operations
    pub async fn create_index(&self, uid: &str) -> Result<Index>;
    pub async fn get_index(&self, uid: &str) -> Result<Index>;
    pub async fn list_indexes(&self) -> Result<Vec<Index>>;
    
    // Document operations
    pub async fn add_documents(&self, documents: Vec<Document>) -> Result<Task>;
    pub async fn search(&self, query: SearchQuery) -> Result<SearchResults>;
    
    // Settings operations
    pub async fn update_settings(&self, settings: Settings) -> Result<Task>;
}
```

## Usage Example

```vlang
// Example usage (to be implemented)
let client = new("http://localhost:7700", "master_key");

// Create an index
let movies = client.create_index("movies").await?;

// Add documents
let documents = vec![
    Document::new()
        .with_id("1")
        .with_field("title", "The Matrix")
        .with_field("year", 1999),
    // ... more documents
];

movies.add_documents(documents).await?;

// Search
let results = movies
    .search()
    .with_query("matrix")
    .with_filter("year > 1990")
    .execute()
    .await?;
```


### Usage Index


```vlang
// Create client
config := meilisearch.ClientConfig{
    host: 'http://localhost:7700'
    api_key: 'master_key'
}
factory := meilisearch.new_factory(config)
mut client := factory.get()!

// Configure index settings
mut settings := meilisearch.IndexSettings{
    ranking_rules: ['typo', 'words', 'proximity']
    searchable_attributes: ['title', 'description']
    displayed_attributes: ['title', 'description', 'price']
}
client.update_settings('movies', settings)!

// Configure typo tolerance
mut typo_settings := meilisearch.TypoTolerance{
    enabled: true
    min_word_size_for_typos: meilisearch.MinWordSizeForTypos{
        one_typo: 4
        two_typos: 8
    }
}
client.update_typo_tolerance('movies', typo_settings)!
```