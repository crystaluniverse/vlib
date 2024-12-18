module rpcwebsocket

import freeflowuniverse.crystallib.rpc.jsonrpc
import log
import net.websocket { Client, Message }
import time

@[heap]
pub struct RpcWsClient {
pub mut:
	client                    &Client
	channel_incoming_messages chan string
	logger                    &log.Logger
}

fn (mut w RpcWsClient) on_message(mut c Client, msg &Message) ! {
	if msg.opcode == .ping {
		c.pong()!
		return
	}
	if msg.opcode == .pong {
		w.logger.debug('Received pong message')
		return
	}
	if msg.opcode != .text_frame && msg.opcode != .binary_frame {
		w.logger.warn('Not a text message: ${msg.opcode}')
		return
	}
	w.channel_incoming_messages <- msg.payload.bytestr()
}

pub fn (mut w RpcWsClient) run() ! {
	w.client.listen()!
}

pub fn (mut w RpcWsClient) send(message string, timeout int) !string {
	// w.logger.debug('Sending message ${message}')
	// if client.client_state == .closed {
	// 	spawn w.run()!
	// }
	_ := w.client.write_string(message)!
	select {
		response := <-w.channel_incoming_messages {
			// w.logger.debug('Received answer ${response}')
			return response
		}
		timeout * time.millisecond {}
	}
	return error('timeout on receiving response from server')
}

pub fn (mut w RpcWsClient) send_json_rpc[T, D](method string, data T, timeout int) !D {
	json_rpc_request := jsonrpc.new_jsonrpcrequest[T](method, data)
	response := w.send(json_rpc_request.to_json(), timeout)!
	error_check := jsonrpc.jsonrpcerror_decode(response) or {
		jsonrpc_response := jsonrpc.jsonrpcresponse_decode[D](response) or {
			return error('Unable to decode ${response}')
		}
		if jsonrpc_response.id != json_rpc_request.id {
			return error('Received response with different id ${response}')
		}
		return jsonrpc_response.result
	}
	return error('Error ${error_check.error.code}: ${error_check.error.message}')
}

pub fn new_rpcwsclient(address string, logger &log.Logger) !&RpcWsClient {
	mut c := websocket.new_client(address, websocket.ClientOpt{})!
	mut rpcwsclient := RpcWsClient{
		client:                    c
		channel_incoming_messages: chan string{}
		logger:                    unsafe { logger }
	}
	c.on_message(rpcwsclient.on_message)
	c.connect()!
	return &rpcwsclient
}

pub fn new_client(address string, logger &log.Logger) !&RpcWsClient {
	mut c := websocket.new_client(address, websocket.ClientOpt{})!
	mut rpcwsclient := RpcWsClient{
		client:                    c
		channel_incoming_messages: chan string{}
		logger:                    unsafe { logger }
	}
	c.on_message(rpcwsclient.on_message)
	c.connect() or { return error('Websocket client failed to connect:\n${err}') }
	return &rpcwsclient
}
