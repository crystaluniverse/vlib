module twinclient
import freeflowuniverse.crystallib.redisclient
import net.websocket as ws
import net.http
import x.json2
import json
import time
import rand

pub fn grid_client(transport ITwinTransport) ?TwinClient {
	return TwinClient{
		transport: transport
	}
}

// Http Client
pub fn (mut htp HttpTwinClient) init()? HttpTwinClient {
	header := http.new_header_from_map({
		http.CommonHeader.content_type: 'application/json',
	})
	url := "http://localhost:3000"
	htp.header = header
	htp.url = url
	htp.method = http.Method.post
	return htp
}

pub fn (htp HttpTwinClient) send(functionPath string, args string)? Message{
	function := functionPath.replace('.', '/')
	request := http.Request{
		url: "$htp.url/$function"
		method: htp.method
		header: htp.header,
		data: args,
	}
	resp := request.do()?

	if resp.status_code == 200{
		raw_body := json2.raw_decode(resp.body)?
		body := raw_body.as_map()["result"]?
		response := Message{
			data: body.str()
		}
		return response
	} else {
		return error(resp.status_msg)
	}
}

// WebSocket Client
pub const factory = Factory{}
pub fn (mut tcl WSTwinClient) init(mut ws_client ws.Client)? WSTwinClient {
	mut f := factory

	if tcl.ws.id in f.clients {
		println("ana hena")
		return factory.clients[tcl.ws.id]
	}
	tcl.ws = ws_client
	tcl.channels = map[string]chan Message{}
	ws_client.on_message(fn [mut tcl] (mut c ws.Client, raw_msg &RawMessage) ? {
		if raw_msg.payload.len == 0 {
			return
		}
		msg := json.decode(Message, raw_msg.payload.bytestr()) or {
			eprintln('cannot decode message payload')
			return
		}
		if msg.event == 'invoke_result' {
			println('processing invoke response: $msg')
			channel := tcl.channels[msg.id] or {
				eprintln('channel for $msg.id is not there')
				return
			}

			println('pushing msg to channel: $msg.id')
			channel <- msg
		}
	})

	ws_client.on_close(fn [mut f] (mut c ws.Client, code int, reason string) ?{
		f.clients.delete(c.id)
	})
	f.clients[tcl.ws.id] = tcl
	return tcl
}

pub fn (mut tcl WSTwinClient) send(functionPath string, args string)? Message {
	id := rand.uuid_v4()
	channel := chan Message{}
	tcl.channels[id] = channel

	mut req := InvokeRequest{}
	req.function = functionPath
	req.args = args

	payload := json.encode(Message{
		id: id
		event: 'invoke'
		data: json.encode(req)
	}).bytes()

	tcl.ws.write(payload, .text_frame)?
	println('waiting for result...')
	return tcl.wait(id, 5) // won't wait more than 300 seconds
}

fn (mut tcl WSTwinClient) wait(id string, timeout u32)? Message {
	if channel := tcl.channels[id] {
		select {
			res := <-channel {
				channel.close()
				tcl.channels.delete(id)
				return res
			}
			timeout * time.second {
				er := "requets with id $id was timed out!"
				channel.close()
				tcl.channels.delete(id)
				return error(er)
			}
		}
	}
	return error('wait channel of $id is not present')
}

// RMB Client
pub fn (mut rmb RmbTwinClient) init(dst []int, exp int, num_retry int)? RmbTwinClient {
	msg := Message{
		id: rand.uuid_v4()
		version: 1
		command: "twinserver"
		expiration: exp
		retry: num_retry
		twin_src: 0
		twin_dst: dst
		retqueue: rand.uuid_v4()
		epoch: time.now().unix_time()
	}
	rmb.client 	= redisclient.get('localhost:6379')?
	rmb.message = msg
	return rmb
}

// pub fn (mut rmb RmbTwinClient) send(functionPath string, args string)? Message{
// 	rmb.data = base64.encode_str(payload)
// 	rmb.command = rmb.command + functionPath
// 	request := json.encode_pretty(update)
// 	bus.client.lpush("msgbus.system.local", request)?
// 	response_stellar := rmb.read(msg_stellar)
// 	for result in response_stellar {
// 		println(result)
// 	}
// }

// pub fn (mut bus MessageBusClient) read(msg Message) []Message {
// 	println('Waiting reply $msg.retqueue')
// 	mut responses := []Message{}
// 	for responses.len < msg.twin_dst.len {
// 		results := bus.client.blpop([msg.retqueue], '0')?
// 		response_json := resp2.get_redis_value(results[1])
// 		mut response_msg := json.decode(Message, response_json)?
// 		response_msg.data = base64.decode_str(response_msg.data)
// 		responses << response_msg
// 	}
// 	return responses
// }