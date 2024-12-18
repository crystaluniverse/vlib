module openrpc

import freeflowuniverse.crystallib.core.codemodel { CodeFile, File, Function, Struct }

pub struct OpenRPCCode {
pub mut:
	openrpc_json File
	handler      CodeFile
	handler_test CodeFile
	client       CodeFile
	client_test  CodeFile
	server       CodeFile
	server_test  CodeFile
}

pub fn (o OpenRPC) generate_code(receiver Struct, methods_map map[string]Function, objects_map map[string]Struct) !OpenRPCCode {
	openrpc_json := o.encode()!
	openrpc_file := File{
		name:      'openrpc'
		extension: 'json'
		content:   openrpc_json
	}

	client_file := o.generate_client_file(objects_map)!
	client_test_file := o.generate_client_test_file(methods_map, objects_map)!

	handler_file := o.generate_handler_file(receiver, methods_map, objects_map)!
	handler_test_file := o.generate_handler_test_file(receiver, methods_map, objects_map)!

	server_file := o.generate_server_file()!
	server_test_file := o.generate_server_test_file()!

	return OpenRPCCode{
		client:       client_file
		client_test:  client_test_file
		handler:      handler_file
		handler_test: handler_test_file
		server:       server_file
		server_test:  server_test_file
		openrpc_json: openrpc_file
	}
}
