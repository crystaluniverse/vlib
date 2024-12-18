module mycelium

import net.http
import json

const server_url = 'http://localhost:8989/api/v1/messages'

pub struct MessageDestination {
pub:
	pk string
}

pub struct PushMessageBody {
pub:
	dst     MessageDestination
	payload string
}

pub struct InboundMessage {
pub:
	id      string
	src_ip  string @[json: 'srcIP']
	src_pk  string @[json: 'srcPk']
	dst_ip  string @[json: 'dstIp']
	dst_pk  string @[json: 'dstPk']
	payload string
}

pub struct MessageStatusResponse {
pub:
	id       string
	dst      string
	state    string
	created  string
	deadline string
	msg_len  string @[json: 'msgLen']
}

pub fn send_msg(pk string, payload string, wait bool) !InboundMessage {
	mut url := server_url
	if wait {
		url = '${url}?reply_timeout=120'
	}
	msg_req := PushMessageBody{
		dst:     MessageDestination{
			pk: pk
		}
		payload: payload
	}
	mut req := http.new_request(http.Method.post, url, json.encode(msg_req))
	req.add_custom_header('content-type', 'application/json')!
	if wait {
		req.read_timeout = 1200000000000
	}
	res := req.do()!
	msg := json.decode(InboundMessage, res.body)!
	return msg
}

pub fn receive_msg(wait bool) !InboundMessage {
	mut url := server_url
	if wait {
		url = '${url}?timeout=60'
	}
	mut req := http.new_request(http.Method.get, url, '')
	if wait {
		req.read_timeout = 600000000000
	}
	res := req.do()!
	msg := json.decode(InboundMessage, res.body)!
	return msg
}

pub fn receive_msg_opt(wait bool) ?InboundMessage {
	mut url := server_url
	if wait {
		url = '${url}?timeout=60'
	}
	mut req := http.new_request(http.Method.get, url, '')
	if wait {
		req.read_timeout = 600000000000
	}
	res := req.do() or { panic(error) }
	if res.status_code == 204 {
		return none
	}
	msg := json.decode(InboundMessage, res.body) or { panic(err) }
	return msg
}

pub fn get_msg_status(id string) !MessageStatusResponse {
	mut url := '${server_url}/status/${id}'
	res := http.get(url)!
	msg_res := json.decode(MessageStatusResponse, res.body)!
	return msg_res
}

pub fn reply_msg(id string, pk string, payload string) !http.Status {
	mut url := '${server_url}/reply/${id}'
	msg_req := PushMessageBody{
		dst:     MessageDestination{
			pk: pk
		}
		payload: payload
	}

	res := http.post_json(url, json.encode(msg_req))!
	return res.status()
}
