module servers.rpcsocket

import net
import json

// RPCRequest represents an incoming JSON-RPC request
struct RPCRequest {
	jsonrpc string    @[required]
	id      int       @[required]
	method  string    @[required]
	params  json.Any
}

// RPCResponse represents a JSON-RPC response
struct RPCResponse {
	jsonrpc string    @[required]
	id      int       @[required]
	result  json.Any
	error   ?RPCError
}

// RPCError represents a JSON-RPC error
struct RPCError {
	code    int
	message string
}

// Server represents the RPC socket server
pub struct Server {
mut:
	listener &net.TcpListener
	port     int
}

// new_server creates a new RPC socket server
pub fn new_server(port int) !&Server {
	listener := net.listen_tcp(.ip6, ':$port')!
	return &Server{
		listener: listener
		port: port
	}
}

// start starts the RPC socket server
pub fn (mut s Server) start() ! {
	println('RPC server listening on port $s.port')
	for {
		mut conn := s.listener.accept() or { continue }
		go s.handle_connection(mut conn)
	}
}

// handle_connection handles an incoming client connection
fn (mut s Server) handle_connection(mut conn net.TcpConn) {
	defer { conn.close() or {} }
	
	for {
		request := conn.read_line() or { break }
		if request.len == 0 { break }
		
		// Parse the JSON-RPC request
		rpc_req := json.decode(RPCRequest, request) or {
			s.send_error(mut conn, 0, -32700, 'Parse error')
			continue
		}
		
		// Handle the RPC method
		response := s.handle_request(rpc_req)
		
		// Send the response
		response_json := json.encode(response)
		conn.write_string(response_json + '\n') or { break }
	}
}

// handle_request processes an RPC request and returns a response
fn (mut s Server) handle_request(req RPCRequest) RPCResponse {
	match req.method {
		'job.set' { return s.handle_job_set(req) }
		'job.get' { return s.handle_job_get(req) }
		'job.delete' { return s.handle_job_delete(req) }
		'job.find' { return s.handle_job_find(req) }
		'executor.set' { return s.handle_executor_set(req) }
		'executor.get' { return s.handle_executor_get(req) }
		'executor.get_by_name' { return s.handle_executor_get_by_name(req) }
		'agent.set' { return s.handle_agent_set(req) }
		'agent.get' { return s.handle_agent_get(req) }
		'joblog.set' { return s.handle_joblog_set(req) }
		'signature.set' { return s.handle_signature_set(req) }
		else {
			return RPCResponse{
				jsonrpc: '2.0'
				id: req.id
				error: RPCError{
					code: -32601
					message: 'Method not found'
				}
			}
		}
	}
}

// Helper function to send an error response
fn (mut s Server) send_error(mut conn net.TcpConn, id int, code int, message string) {
	response := RPCResponse{
		jsonrpc: '2.0'
		id: id
		error: RPCError{
			code: code
			message: message
		}
	}
	response_json := json.encode(response)
	conn.write_string(response_json + '\n') or {}
}

// Job RPC handlers
fn (mut s Server) handle_job_set(req RPCRequest) RPCResponse {
	// Parse job parameters
	job_params := req.params.as_map()
	job := job_params['job'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Invalid job parameters'
			}
		}
	}

	// TODO: Implement job creation/update logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: job
	}
}

fn (mut s Server) handle_job_get(req RPCRequest) RPCResponse {
	// Parse job ID
	params := req.params.as_map()
	id := params['id'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Missing job ID'
			}
		}
	}

	// TODO: Implement job retrieval logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: json.null
	}
}

fn (mut s Server) handle_job_delete(req RPCRequest) RPCResponse {
	// Parse job ID
	params := req.params.as_map()
	id := params['id'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Missing job ID'
			}
		}
	}

	// TODO: Implement job deletion logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: true
	}
}

fn (mut s Server) handle_job_find(req RPCRequest) RPCResponse {
	// Parse search parameters
	params := req.params.as_map()
	search_params := params['params'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Missing search parameters'
			}
		}
	}

	// TODO: Implement job search logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: []json.Any{}
	}
}

// Executor RPC handlers
fn (mut s Server) handle_executor_set(req RPCRequest) RPCResponse {
	// Parse executor parameters
	params := req.params.as_map()
	executor := params['executor'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Invalid executor parameters'
			}
		}
	}

	// TODO: Implement executor creation/update logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: executor
	}
}

fn (mut s Server) handle_executor_get(req RPCRequest) RPCResponse {
	// Parse executor ID
	params := req.params.as_map()
	id := params['id'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Missing executor ID'
			}
		}
	}

	// TODO: Implement executor retrieval logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: json.null
	}
}

fn (mut s Server) handle_executor_get_by_name(req RPCRequest) RPCResponse {
	// Parse executor name
	params := req.params.as_map()
	name := params['name'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Missing executor name'
			}
		}
	}

	// TODO: Implement executor retrieval by name logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: json.null
	}
}

// Agent RPC handlers
fn (mut s Server) handle_agent_set(req RPCRequest) RPCResponse {
	// Parse agent parameters
	params := req.params.as_map()
	agent := params['agent'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Invalid agent parameters'
			}
		}
	}

	// TODO: Implement agent creation/update logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: agent
	}
}

fn (mut s Server) handle_agent_get(req RPCRequest) RPCResponse {
	// Parse agent ID
	params := req.params.as_map()
	id := params['id'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Missing agent ID'
			}
		}
	}

	// TODO: Implement agent retrieval logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: json.null
	}
}

// Job Log RPC handlers
fn (mut s Server) handle_joblog_set(req RPCRequest) RPCResponse {
	// Parse job log parameters
	params := req.params.as_map()
	log := params['log'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Invalid job log parameters'
			}
		}
	}

	// TODO: Implement job log creation/update logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: log
	}
}

// Signature RPC handlers
fn (mut s Server) handle_signature_set(req RPCRequest) RPCResponse {
	// Parse signature request parameters
	params := req.params.as_map()
	request := params['request'] or {
		return RPCResponse{
			jsonrpc: '2.0'
			id: req.id
			error: RPCError{
				code: 400
				message: 'Invalid signature request parameters'
			}
		}
	}

	// TODO: Implement signature request creation/update logic
	
	return RPCResponse{
		jsonrpc: '2.0'
		id: req.id
		result: request
	}
}
