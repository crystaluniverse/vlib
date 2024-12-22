# HTTPConnection Module

The HTTPConnection module provides a robust HTTP client implementation with support for JSON handling, custom headers, retries, and caching.

## Features

- Generic JSON methods for type-safe requests
- Custom header support
- Built-in retry mechanism
- Cache configuration
- URL encoding support

## Basic Usage

```v
import freeflowuniverse.crystallib.clients.httpconnection

// Create a new HTTP connection
mut conn := HTTPConnection{
    base_url: 'https://api.example.com'
    retry: 5  // number of retries for failed requests
}
```

## Examples

### GET Request with JSON Response

```v
// Define your data structure
struct User {
    id    int
    name  string
    email string
}

// Make a GET request and decode JSON response
user := conn.get_json_generic[User](
    method: .get
    prefix: 'users/1'
    dataformat: .urlencoded
)!
```

### GET Request for List of Items

```v
// Get a list of items and decode each one
users := conn.get_json_list_generic[User](
    method: .get
    prefix: 'users'
    list_dict_key: 'users'  // if response is wrapped in a key
    dataformat: .urlencoded
)!
```

### POST Request with JSON Data

```v
// Create new resource with POST
new_user := conn.post_json_generic[User](
    method: .post
    prefix: 'users'
    dataformat: .urlencoded
    params: {
        'name': 'John Doe'
        'email': 'john@example.com'
    }
)!
```

### Real-World Example: SSH Key Management

Here's a practical example inspired by SSH key management in a cloud API:

```v
// Define the SSH key structure
struct SSHKey {
pub mut:
    name        string
    fingerprint string
    type_       string    @[json: 'type']
    size        int
    created_at  string
    data        string
}

// Get all SSH keys
fn get_ssh_keys(mut conn HTTPConnection) ![]SSHKey {
    return conn.get_json_list_generic[SSHKey](
        method: .get
        prefix: 'key'
        list_dict_key: 'key'
        dataformat: .urlencoded
    )!
}

// Create a new SSH key
fn create_ssh_key(mut conn HTTPConnection, name string, key_data string) !SSHKey {
    return conn.post_json_generic[SSHKey](
        method: .post
        prefix: 'key'
        dataformat: .urlencoded
        params: {
            'name': name
            'data': key_data
        }
    )!
}

// Delete an SSH key
fn delete_ssh_key(mut conn HTTPConnection, fingerprint string) ! {
    conn.delete(
        method: .delete
        prefix: 'key/${fingerprint}'
        dataformat: .urlencoded
    )!
}
```

## Custom Headers

You can set default headers for all requests or specify headers for individual requests:

```v
import net.http { Header }

// Set default headers for all requests
conn.default_header = http.new_header(
    key: .authorization
    value: 'Bearer your-token-here'
)

// Add custom headers for specific request
response := conn.get_json(
    method: .get
    prefix: 'protected/resource'
    header: http.new_header(
        key: .content_type
        value: 'application/json'
    )
)!
```

## Error Handling

The module uses V's built-in error handling. All methods that can fail return a Result type:

```v
// Handle potential errors
user := conn.get_json_generic[User](
    method: .get
    prefix: 'users/1'
) or {
    println('Error: ${err}')
    return
}
```

## Cache Configuration

The module supports caching of responses. Configure caching behavior through the `CacheConfig` struct:

```v
mut conn := HTTPConnection{
    base_url: 'https://api.example.com'
    cache: CacheConfig{
        enabled: true
        // Add other cache configuration as needed
    }
}
