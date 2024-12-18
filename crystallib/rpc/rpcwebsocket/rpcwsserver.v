module rpcwebsocket

import log
import net.websocket { Client, Message, Server, ServerClient }

type MessageHandler = fn (client &Client, message string) string

@[heap]
pub struct RpcWsServer {
pub mut:
	server  &Server
	logger  &log.Logger
	handler MessageHandler @[required]
}

fn (mut rws RpcWsServer) on_message(mut client Client, msg &Message) ! {
	if msg.opcode == .ping {
		client.pong()!
		return
	}
	if msg.opcode == .pong {
		rws.logger.debug('Received pong from client')
		return
	}
	if msg.opcode != .text_frame && msg.opcode != .binary_frame {
		rws.logger.warn('Not a text message: ${msg.opcode}')
		return
	}

	response := rws.handler(client, msg.payload.bytestr())
	client.write_string(response)!
}

fn (mut rws RpcWsServer) on_close(mut client Client, code int, reason string) ! {
	rws.logger.info('Closing connection to client')
}

fn (mut rws RpcWsServer) on_connect(mut client ServerClient) !bool {
	rws.logger.info('New client connection')
	return true
}

pub fn (mut rws RpcWsServer) run() ! {
	rws.logger.info('Lets start listening!')
	rws.server.listen()!
}

pub fn new_rpcwsserver(port int, handler MessageHandler, logger &log.Logger) !&RpcWsServer {
	mut server := websocket.new_server(.ip, port, '', websocket.ServerOpt{
		logger: unsafe { logger }
	})
	rpcwsserver := RpcWsServer{
		server:  server
		handler: handler
		logger:  unsafe { logger }
	}

	server.on_connect(rpcwsserver.on_connect)!
	server.on_message(rpcwsserver.on_message)
	server.on_close(rpcwsserver.on_close)

	return &rpcwsserver
}
