module openapi

import net.http {CommonHeader}
import x.json2 {Any}

pub struct Request {
pub:
	path   string            // The requested path
	method string            // HTTP method (e.g., GET, POST)
	key string
	body   string            // Request body
	operation Operation
	arguments map[string]Any
	parameters map[string]string
	header http.Header @[omitempty; str: skip; json: '-']// Request headers
}

pub struct Response {
pub mut:
	status http.Status            // HTTP status
	body        string         // Response body
	header	http.Header @[omitempty; str: skip; json:'-']// Response headers
}

pub interface IHandler {
mut:
    handle(Request) !Response
}

pub struct Handler {
pub:
	routes map[string]fn (Request) !Response // Map of route handlers
}

// Handle a request and return a response
pub fn (handler Handler) handle(request Request) !Response {
    // Match the route based on the request path
    if route_handler := handler.routes[request.path] {
        // Call the corresponding route handler
        return route_handler(request)
    }

    // Return 404 if no route matches
    return Response{
        status: .not_found
        body: 'Not Found'
        header: http.new_header(
			key: CommonHeader.content_type,
			value: 'text/plain'
		)
    }
}

