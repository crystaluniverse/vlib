# HTTP Connection Module

A powerful HTTP client for V with built-in Redis caching capabilities. This module provides a clean interface for making HTTP requests with optional caching support.

## Features

- Simple HTTP client interface
- Built-in Redis caching
- Support for all common HTTP methods (GET, POST, DELETE, etc.)
- Custom header management
- JSON handling utilities
- Multipart form data support
- Configurable retry mechanism

## Basic Usage

### Creating a Connection

```v
import freeflowuniverse.crystallib.clients.httpconnection

// Create a new connection without caching
mut conn := httpconnection.new(
    name: 'api_client',
    url: 'http://api.example.com'
)!

// Create a connection with caching enabled
mut cached_conn := httpconnection.new(
    name: 'cached_api',
    url: 'http://api.example.com',
    cache: true
)!
```

### Making Requests

```v
// Simple GET request
response := conn.get(prefix: 'users')!
println(response)

// GET request with parameters
response := conn.get(
    prefix: 'users'
    params: {
        'page': '1'
        'limit': '10'
    }
)!

// POST request with JSON data
response := conn.post_json_str(Request{
    prefix: 'users'
    data: '{"name": "John", "age": 30}'
})!

// DELETE request
response := conn.delete(prefix: 'users/123')!
```

### Working with JSON

```v
// Get response as JSON dictionary
data := conn.get_json_dict(Request{
    prefix: 'users/profile'
})!

// Get JSON array response
users := conn.get_json_list(Request{
    prefix: 'users'
})!
```

## Caching Mechanism

The module uses Redis for caching HTTP responses. When enabled, it can significantly improve performance for frequently accessed endpoints.

### How Caching Works

1. **Cache Key Generation**: 
   - Cache keys are generated based on:
     - HTTP method
     - URL (MD5 hashed)
     - Request data
     - Headers (if match_headers is enabled)

2. **Cache Control**:
   - Cache can be:
     - Enabled/disabled globally for the connection
     - Disabled per request using `cache_disable: true`
     - Configured to expire after a specific time
     - Automatically invalidated for unsafe methods (POST, PUT, DELETE)

### Caching Example

```v
// Create connection with caching
mut conn := httpconnection.new(
    name: 'cached_api',
    url: 'http://api.example.com',
    cache: true
)!

// This request will be cached
response1 := conn.get(prefix: 'users/123')!

// This request will fetch from cache if available
response2 := conn.get(prefix: 'users/123')!

// Disable cache for specific request
response3 := conn.get(Request{
    prefix: 'users/123'
    cache_disable: true
})!

// Clear entire cache for this connection
conn.cache_drop()!
```

## Advanced Examples

### Custom Headers and Retry

```v
mut conn := httpconnection.new(
    name: 'api_client',
    url: 'http://api.example.com',
    retry: 3  // Will retry failed requests up to 3 times
)!

// Add custom headers
conn.default_header.add(.authorization, 'Bearer your-token-here')

// Make authenticated request
response := conn.get(Request{
    prefix: 'protected/resource'
    header: http.new_header_from_map({
        .accept: 'application/json'
    })
})!
```

### Multipart Form Data

```v
import net.http

mut conn := httpconnection.new(
    name: 'upload_client',
    url: 'http://api.example.com'
)!

// Configure multipart form
mut form := http.PostMultipartFormConfig{
    files: {
        'file': '/path/to/file.pdf'
    }
    data: {
        'description': 'My uploaded file'
    }
}

// Send multipart request
response := conn.post_multi_part(Request{
    prefix: 'upload'
}, form)!
```

### Error Handling

```v
mut conn := httpconnection.new(
    name: 'api_client',
    url: 'http://api.example.com'
)!

// Using error handling
response := conn.get(prefix: 'users') or {
    if err.msg().contains('404') {
        // Handle not found
        return error('User not found')
    }
    return err
}

// Check response status
result := conn.send(Request{
    method: .get
    prefix: 'status'
})!

if result.is_ok() {
    // Handle successful response (status 200-399)
} else {
    // Handle error response
}
