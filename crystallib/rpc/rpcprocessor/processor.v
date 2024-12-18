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
import freeflowuniverse.crystallib.ui.console

const eb = eventbus.new[string]()

pub struct EventMetadata {
pub:
	message string
}

pub fn get_subscriber() eventbus.Subscriber[string] {
	return *eb.subscriber
}

@[heap]
struct RPCProcessor {
mut:
	logger        &log.Logger = &log.Logger(&log.Log{
	level: .debug
})
	redis_client  redisclient.Redis
	handler_queue string = 'rpc_handler_queue'
	result_queue  string = 'rpc_result_queue'
	// ws_server    rpcwebsocket.RpcWsServer // Placeholder for your WebSocket server type
pub mut:
	handlers []IHandler
}

// Handler is the structure responsible of handling a list of supported RPCs over a redis queue
pub interface IHandler {
	name          string   // name of handler
	methods       []string // list of supported methods
	description   string
	threads       int
	typ           string
	last_activity time.Time
	activity      []Activity
	rpc_no        int
	average_time  time.Duration
	success_rate  f64
mut:
	queue redisclient.RedisQueue // queue of handler
}

// Handler is the structure responsible of handling a list of supported RPCs over a redis queue
pub struct Handler {
pub:
	name          string   // name of handler
	methods       []string // list of supported methods
	description   string
	threads       int
	typ           string
	last_activity time.Time
	activity      []Activity
	rpc_no        int
	average_time  time.Duration
	success_rate  f64
mut:
	queue redisclient.RedisQueue // queue of handler
}

struct RPCRequest {
	id      string
	payload string
}

struct RPCResponse {
	id     string
	result string
}

@[params]
pub struct ProcessorConfig {
	redis_client redisclient.Redis
}

pub fn new(config ProcessorConfig) !RPCProcessor {
	// Initialize Redis client

	processor := RPCProcessor{
		redis_client: config.redis_client
	}

	return processor
}

pub fn (mut p RPCProcessor) register_handler(handler IHandler) {
	p.handlers << handler
}

struct API {}

pub fn new_api() API {
	api := API{}
	mut sub := get_subscriber()
	sub.subscribe_method('event_foo', on_foo, api)
	return api
}

fn on_foo(mut receiver API, e &EventMetadata, sender voidptr) {
	console.print_debug('on_foo :: ' + e.message)
}

// pub fn (mut ui RPCProcessorUI) handler() vweb.Result {
//     return ui.html($tmpl('./templates/handler.html'))
// }

struct Activity {
pub:
	name   string
	caller string
	method string
	time   time.Time
	rpc_id string
}

pub struct Duration {
pub:
	hours int
}

fn (mut p RPCProcessor) handler(client &websocket.Client, message string) string {
	method := jsonrpc.jsonrpcrequest_decode_method(message) or { return '' }
	id := jsonrpc.jsonrpcrequest_decode_id(message) or { return '' }
	p.logger.info('Processing RPC ${id}')

	duration := Duration{10}

	event_metadata := &EventMetadata{'Processing RPC ${id}'}
	eb.publish('event_foo', duration, event_metadata)

	p.redis_client.hset('rpcs.db', id, message) or { panic(err) }

	// mut q_handler := p.redis_client.queue_get(method)
	mut handler := p.get_method_handler(method) or { panic('Handler for RPC ${method} not found') }
	p.logger.info('Adding RPC to handler: `${handler.name}` queue.')
	handler.queue.add(id) or { panic(err) }

	mut q_response := p.redis_client.queue_get(id)
	p.logger.info('Awaiting response to RPC `${id}` in queue.')
	response := q_response.get(1000) or { panic(err) }
	console.print_debug('message: ${response}')
	return response
}

// returns, if exists, the handler responsible for the RPC Call
fn (p RPCProcessor) get_method_handler(method string) ?IHandler {
	handlers := p.handlers.filter(method in it.methods)
	if handlers.len > 1 {
		panic('multiple handlers for method found, this should never happen')
	} else if handlers.len == 0 {
		return none
	}
	return handlers[0]
}
