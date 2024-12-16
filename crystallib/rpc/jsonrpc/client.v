module jsonrpc

import log

pub interface IRpcTransportClient {
mut:
	send(string, int) !string
}

// JSON-RPC WebSoocket Server
pub interface IJsonRpcClient {
mut:
	transport IRpcTransportClient
}

pub fn (mut client IJsonRpcClient) send_json_rpc[T, D](method string, data T, timeout int) !D {
	json_rpc_request := new_jsonrpcrequest[T](method, data)
	response := client.transport.send(json_rpc_request.to_json(), timeout)!
	error_check := jsonrpcerror_decode(response) or {
		jsonrpc_response := jsonrpcresponse_decode[D](response) or {
			return error('Unable to decode ${response}')
		}
		if jsonrpc_response.id != json_rpc_request.id {
			return error('Received response with different id ${response}')
		}
		return jsonrpc_response.result
	}
	return error('Error ${error_check.error.code}: ${error_check.error.message}')
}

@[params]
pub struct ClientConfig {
	address string // address of ws server
}
