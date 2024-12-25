module openrouter

import json
import net.http
import freeflowuniverse.crystallib.clients.httpconnection { Request }

// Message represents a single message in the conversation
// pub struct Message {
// pub mut:
// 	role    string
// 	content string
// 	name    string // optional
// }

// CompletionRequest represents the request body for chat completions
pub struct CompletionRequest {
pub mut:
	model       string
	messages    []Message
	temperature f64 = 0.7
	max_tokens  int
	// OpenRouter specific fields
	transforms []string // optional
	route      string   // optional
	// Site info for rankings (optional)
	http_referer    string
	http_user_agent string
}

// Choice represents a single completion choice in the response
// pub struct Choice {
// pub mut:
// 	index         int
// 	message       Message
// 	finish_reason string
// }

// Usage represents token usage information
// pub struct Usage {
// pub mut:
// 	prompt_tokens     int
// 	completion_tokens int
// 	total_tokens      int
// }

// CompletionResponse represents the API response for chat completions
pub struct CompletionResponse {
pub mut:
	id                 string
	choices            []Choice
	created            int
	model              string
	usage              Usage
	system_fingerprint string
}

// create_completion sends a completion request to OpenRouter API
pub fn (mut client OpenRouterClient) create_completion(req CompletionRequest) !CompletionResponse {
	mut conn := client.connection()!

	// Set required headers
	mut headers := http.new_header()
	headers.add_custom('HTTP-Referer', req.http_referer) or {}
	headers.add_custom('HTTP-User-Agent', req.http_user_agent) or {}

	// Prepare request
	mut request := Request{
		method:     .post
		prefix:     'chat/completions'
		data:       json.encode(req)
		header:     headers
		dataformat: .json
	}

	// Send request and decode response
	response := conn.do(request)!
	return json.decode(CompletionResponse, response)!
}

// Helper method to create a connection
// fn (client OpenRouterClient) connection() !httpconnection.Connection {
// 	mut conn := httpconnection.new(
// 		base_url:   'https://openrouter.ai/api/v1'
// 		auth_type:  .bearer
// 		auth_token: client.openrouter_apikey
// 	)!
// 	return conn
// }
