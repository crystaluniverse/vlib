module rpcprocessor

import freeflowuniverse.crystallib.clients.redisclient // Assuming this is the path to the Redis client
import freeflowuniverse.crystallib.data.rpcwebsocket // Assuming this is the path to the Redis client
import freeflowuniverse.crystallib.data.jsonrpc
import net.websocket
import time
import vweb
import log
import eventbus
import rand

const mock_activity = Activity{
	caller: '127.0.0.1'
	method: 'mock_rpc_method'
	time:   time.now()
	rpc_id: rand.uuid_v4()
}

fn new_mock_handler() !Handler {
	mut redis_client := redisclient.core_get()!
	return Handler{
		name:         'Mock handler'
		description:  'This is a mock handler that is used for examples'
		queue:        redis_client.queue_get('mock')
		activity:     [
			mock_activity,
			mock_activity,
			mock_activity,
		]
		rpc_no:       405
		threads:      3
		success_rate: 98.5
		average_time: 365 * time.millisecond
		typ:          'OpenRPC Handler'
	}
}

struct Client {
mut:
	wsclient &rpcwebsocket.RpcWsClient
}

pub fn new_client() !Client {
	logger := &log.Logger(&log.Log{
		level: .debug
	})
	return Client{
		wsclient: rpcwebsocket.new_rpcwsclient('ws://127.0.0.1:8001', logger)!
	}
}

pub fn (c Client) get_handlers() ![]Handler {
	return [
		new_mock_handler()!,
		new_mock_handler()!,
		new_mock_handler()!,
	]
}

pub fn (mut c Client) get_handler(name string) !Handler {
	req := c.wsclient.send_json_rpc[string, Handler]('get_handler', name, 10000)!
	return new_mock_handler()!
}

pub fn (c Client) get_rpc(id string) !Activity {
	return mock_activity
}

pub fn (c Client) get_latest_activity() ![]Activity {
	return [
		mock_activity,
		mock_activity,
		mock_activity,
	]
}
