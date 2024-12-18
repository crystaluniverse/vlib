module main

// Example route handler function
fn example_route_handler(request Request) !Response {
    return Response{
        status_code: 200
        body: 'Hello, this is the example route!'
        headers: {'Content-Type': 'text/plain'}
    }
}

// Example usage
fn main() {
    // Initialize the handler with routes
    handler := Handler{
        routes: {
            '/example': example_route_handler
        }
    }

    // Create a sample request
    request := Request{
        path: '/example'
        method: 'GET'
        body: ''
        headers: {}
    }

    // Handle the request
    response := handler.handle(request) or {
        eprintln('Error handling request: $err')
        return
    }

    // Print the response
    println('Response:')
    println('Status: $response.status_code')
    println('Body: $response.body')
    println('Headers: $response.headers')
}