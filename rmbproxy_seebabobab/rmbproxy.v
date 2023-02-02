module rmbproxy
import freeflowuniverse.crystallib.encoder
import freeflowuniverse.crystallib.redisclient

import log
import net.websocket

[heap]
pub struct RMBProxy {
pub mut:
	redis redisclient.Redis
	wsserver &websocket.Server
	logger &log.Logger
	handlers map[string]RMBProxyMessageHandler
	clients [u32]&websocket.ServerClient
}

pub fn new(port int, logger &log.Logger) !RMBProxy {
	mut redis := redisclient.core_get()
	mut wsserver := websocket.new_server(.ip, port, "", websocket.ServerOpt{ logger: unsafe { logger } })
	mut rmbp := RMBProxy {
		redis: redis
		wsserver: wsserver
		logger: unsafe { logger }
	}
	mut handlers := map[string]RMBProxyMessageHandler{}
	handlers["job.send"] = JobSendHandler { rmbp: &rmbp }
	handlers["twin.set"] = TwinSetHandler { rmbp: &rmbp }
	handlers["twin.del"] = TwinDelHandler { rmbp: &rmbp }
	handlers["twin.get"] = TwinGetHandler { rmbp: &rmbp }
	handlers["twinid.new"] = TwinIdNewHandler { rmbp: &rmbp }
	handlers["proxies.get"] = ProxiesGetHandler { rmbp: &rmbp }
	rmbp.handlers = handlers

	wsserver.on_connect(rmbp.on_connect)!
	wsserver.on_message(rmbp.on_message)
	wsserver.on_close(rmbp.on_close)
	return rmbp
}

fn (mut rmbp RMBProxy) on_close(mut client websocket.Client, code int, reason string) ! {
	rmbp.logger.info("Closing connection to client")
}

fn (mut rmbp RMBProxy) on_connect(mut client websocket.ServerClient) !bool {
	rmbp.logger.info("New client connection")

	return true
}

fn (mut rmbp RMBProxy) on_message(mut client websocket.Client, msg &websocket.Message) ! {
	if msg.opcode == .binary_frame {
		rmbp.logger.debug("New message: ${msg.payload}")
		mut decoder := encoder.decoder_new(msg.payload)
		data := decoder.get_map_string()

		if !("cmd" in data) {
			rmbp.logger.error("Invalid message <${data}>: Does not contain cmd")
			return 
		}

		if !(data["cmd"] in rmbp.handlers) {
			rmbp.logger.error("Invalid message <${data}>: Unknown command ${data['cmd']}")
			return 
		}

		response := rmbp.handlers[data["cmd"]].handle(mut &client, data) or {
			rmbp.logger.error("Error while handeling message <${data}>: $err")
			return
		}
		rmbp.logger.info("Successfully handled message of type: ${data["cmd"]}")
	}
}


//run the rmb processor
pub fn run(port int, logger &log.Logger) ! {
	mut rmbproxy := new(port, logger)!
	rmbproxy.wsserver.listen()!
}