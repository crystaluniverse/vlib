module natsclient

import json
import log
import net.websocket
import rand
import time

const logger_prefix = '[NATSClient ]'
const natsclient_version_major = u8(0)
const natsclient_version_minor = u8(0)
const natsclient_version_patch = u8(1)
const inbox_stream_create = 'stream.create'
const inbox_consumer_create = 'consumer.create'
const inbox_message = 'message'
const inbox_kv_create = 'kv.create'
const inbox_kv_add = 'kv.add'
const inbox_kv_get = 'kv.get'
const inbox_kv_set = 'kv.set'
const kv_stream_prefix = 'KV_'
const kv_subject_prefix = '\$KV.'

pub const natsclient_version = '${natsclient_version_major}.${natsclient_version_minor}.${natsclient_version_patch}'

type ConsumerList = []string

@[heap]
pub struct NATSClient {
mut:
	uuid                string
	myinbox             string
	websocket           &websocket.Client
	address             string
	stream_to_consumers map[string]ConsumerList

	ch_messages   chan NATSMessage
	ch_keyvalue   chan NATSKeyValue
	natsmsgparser &NATSMessageParser
pub mut:
	// pull every 5 seconds
	pull_frequency int = 5
	logger         &log.Logger
}

fn (mut cl NATSClient) on_message(mut client websocket.Client, msg &websocket.Message) ! {
	payload := msg.payload.bytestr()
	cl.logger.debug("${logger_prefix} New message: \"${payload.trim_space()}\"")
	cl.natsmsgparser.parse(payload) or {
		cl.logger.error("${logger_prefix} Error parsing payload \"${payload}\": ${err}")
	}
}

pub fn (mut cl NATSClient) ack_message(ack_subject string) {
	// setting reply_to results in receiving a message once the ACK has been received by the server
	// though the received message is empty and has the same sid for all messages in that batch...
	cl.publish(ack_subject, '', '') or {
		cl.logger.error('${logger_prefix} Acknowledge message: Failed to send message')
	}
}

pub fn (mut cl NATSClient) create_stream(name string, subjects []string) ! {
	if name == '' {
		return error('Please provide a non empty name for the stream')
	}
	cl.logger.info('${logger_prefix} Creating stream with name ${name}')
	stream_config := json.encode(StreamConfig{
		name:     name
		subjects: subjects
	})
	// TODO we receive that message in our inbox: we should parse it and if its an error
	// handle it
	cl.publish('\$JS.API.STREAM.CREATE.${name}', '${cl.myinbox}.${inbox_stream_create}',
		stream_config) or { return error('Create stream: failed to send message') }
	cl.stream_to_consumers[name] = []string{}
}

pub fn (mut cl NATSClient) create_consumer(name string, stream string, description string) ! {
	if name == '' {
		return error('Please provide a non empty name for the consumer')
	}
	if stream !in cl.stream_to_consumers {
		return error("Can't create consumer on stream ${stream}: stream doesn't exist!")
	}
	cl.logger.info('${logger_prefix} Creating consumer for stream ${stream} with name ${name}')
	consumer_config := json.encode(ConsumerConfig{
		stream_name: stream
		config:      struct {
			name:        name
			description: description
			// TODO experiment with all => this would only require us to acknowledge the last message of a batch of messages
			ack_policy: 'explicit'
		}
	})
	cl.publish('\$JS.API.CONSUMER.CREATE.${stream}.${name}', '${cl.myinbox}.${inbox_consumer_create}',
		consumer_config)!
	cl.stream_to_consumers[stream] << name
}

fn (mut cl NATSClient) pull_messages(batch_size int, expires i64) {
	cl.logger.info('${logger_prefix} Sending pull request with batch size ${batch_size}')
	for stream, consumers in cl.stream_to_consumers {
		for consumer in consumers {
			next_msg := json.encode(ConsumerNextMSG{
				expires: expires * time.second
				batch:   batch_size
				no_wait: false
			})
			// Passing the reply_to results in getting a response message from the server. This can be an
			// error or the configuration that the server used (with all default params too). We should
			// handle the error and or parse the object
			cl.publish('\$JS.API.CONSUMER.MSG.NEXT.${stream}.${consumer}', '${cl.myinbox}.${inbox_message}',
				next_msg) or { cl.logger.error('${logger_prefix} Failed to pull messages') }
		}
	}
}

pub fn (mut cl NATSClient) subscribe(subject string) !string {
	cl.logger.info('${logger_prefix} Subscribing to subject ${subject}')
	sid := rand.uuid_v4()
	data := 'SUB ${subject} ${sid}\r\n'
	cl.logger.debug('${logger_prefix} Sending: ${data.trim_space()}')
	cl.websocket.write(data.bytes(), .binary_frame) or {
		return error('Subscribe: Failed to send message')
	}
	return sid
}

pub fn (mut cl NATSClient) publish(subject string, reply_to string, message string) ! {
	// TODO if reply_to != "" subscribe to that subject and handel messages that we
	// get from it
	data := if reply_to == '' {
		'PUB ${subject} ${message.len}\r\n${message}\r\n'
	} else {
		'PUB ${subject} ${reply_to} ${message.len}\r\n${message}\r\n'
	}
	cl.logger.debug('${logger_prefix} Sending: ${data.trim_space()}')
	cl.websocket.write(data.bytes(), .binary_frame) or {
		return error('Publish: Failed to send message')
	}
}

pub fn (mut cl NATSClient) hpublish(subject string, headers map[string]string, reply_to string, message string) ! {
	mut header_payload := 'NATS/1.0\r\n'
	for header, val in headers {
		header_payload += '${header}: ${val}\r\n'
	}
	header_payload += '\r\n'
	total_payload_len := header_payload.len + message.len
	data := if reply_to == '' {
		'HPUB ${subject} ${header_payload.len} ${total_payload_len}\r\n${header_payload}${message}\r\n'
	} else {
		'HPUB ${subject} ${reply_to} ${header_payload.len} ${total_payload_len}\r\n${header_payload}${message}\r\n'
	}
	cl.logger.debug('${logger_prefix} Sending: ${data.trim_space()}')
	cl.websocket.write(data.bytes(), .binary_frame) or {
		return error('HPublish: Failed to send message')
	}
}

pub fn (mut cl NATSClient) create_keyvalue_store(name string) ! {
	stream_config := json.encode(StreamConfig{
		name:                 '${kv_stream_prefix}${name}'
		subjects:             ['${kv_subject_prefix}${name}.>']
		retention:            'limits'
		max_consumers:        -1
		max_msgs:             -1
		max_bytes:            -1
		discard:              'new'
		max_age:              0
		max_msgs_per_subject: 1
		max_msg_size:         -1
		storage:              'file'
		num_replicas:         1
		duplicate_window:     120000000000
		placement:            struct {
			cluster: ''
		}
		deny_delete:          true
		allow_rollup_hdrs:    true
		allow_direct:         true
		mirror_direct:        false
	})
	cl.publish('\$JS.API.STREAM.CREATE.KV_${name}', '${cl.myinbox}.${inbox_kv_create}',
		stream_config) or { return error('Create KeyValue store: failed to send message') }
}

pub fn (mut cl NATSClient) add_keyvalue(store string, key string, value string) ! {
	mut headers := map[string]string{}
	headers['Nats-Expected-Last-Subject-Sequence'] = '0'
	cl.hpublish('\$KV.${store}.${key}', headers, '${cl.myinbox}.${inbox_kv_add}', value) or {
		return error('Add Key-Value: failed to send message')
	}
}

pub fn (mut cl NATSClient) set_value(store string, key string, value string) ! {
	cl.publish('\$KV.${store}.${key}', '${cl.myinbox}.${inbox_kv_set}', value) or {
		return error('Set Value: failed to send message')
	}
}

pub fn (mut cl NATSClient) get_value(store string, key string) ! {
	cl.publish('\$JS.API.DIRECT.GET.KV_${store}.\$KV.${store}.${key}', '${cl.myinbox}.${inbox_kv_get}',
		'') or { return error('Get Value: failed to send message') }
}

fn (mut cl NATSClient) send_ping() {
	cl.logger.debug('PING >')
	cl.websocket.write('PING\r\n'.bytes(), .binary_frame) or {
		cl.logger.error('Failed to send PING')
	}
}

fn (mut cl NATSClient) send_pong() {
	cl.logger.debug('${logger_prefix} PONG >')
	cl.websocket.write('PONG\r\n'.bytes(), .binary_frame) or {
		cl.logger.error('${logger_prefix} Failed to send PONG')
	}
}

fn (mut cl NATSClient) send_connect() {
	cl.logger.info('${logger_prefix} Connecting with NATSServer')
	message_data := json.encode(ConnectConfig{
		verbose:       false
		pedantic:      true
		tls_required:  false
		name:          'v_client_${cl.uuid}'
		lang:          'V'
		version:       natsclient_version
		protocol:      1
		echo:          true
		headers:       true
		no_responders: true
	})
	data := 'CONNECT ${message_data}\r\n'
	cl.logger.debug('${logger_prefix} Sending data: ${data}')
	cl.websocket.write(data.bytes(), .binary_frame) or {
		cl.logger.error('${logger_prefix} Failed to send message')
	}
}

fn (mut cl NATSClient) nats_message(message NATSMessage, headers map[string]string) {
	cl.logger.debug('${logger_prefix} ${message}')

	if message.subject.starts_with(cl.myinbox) {
		match message.subject {
			'${cl.myinbox}.${inbox_kv_get}' {
				if !cl.ch_keyvalue.closed {
					store := headers['Nats-Stream'][kv_stream_prefix.len..]
					keyval := NATSKeyValue{
						store:     store
						key:       headers['Nats-Subject'][kv_subject_prefix.len + store.len + 1..]
						value:     message.message
						timestamp: headers['Nats-Time-Stamp']
					}
					cl.ch_keyvalue <- keyval
				}
			}
			'${cl.myinbox}.${inbox_kv_add}' {
				// inbox for adding a key value pair in the store
				// TODO parse errors etc
				cl.logger.info('${logger_prefix} ${message}\n${headers}')
			}
			'${cl.myinbox}.${inbox_kv_set}' {
				// inbox for creating a setting a value of a key
			}
			'${cl.myinbox}.${inbox_kv_create}' {
				// inbox for creating a key value store
				// TODO parse errors
			}
			'${cl.myinbox}.${inbox_stream_create}' {
				// inbox for creating a stream
				// TODO parse errors
			}
			'${cl.myinbox}.${inbox_consumer_create}' {
				// inbox for creating a consumer
				// TODO parse errors
			}
			'${cl.myinbox}.${inbox_message}' {
				// inbox for pulling messages telling us it is empty					
			}
			else {
				cl.logger.info('${logger_prefix} ${message}\n${headers}')
			}
		}
	} else {
		if !cl.ch_messages.closed {
			cl.ch_messages <- message
		}
	}
}

fn (mut cl NATSClient) nats_info(data string) {
	cl.logger.info('${logger_prefix} ${data}')
}

fn (mut cl NATSClient) nats_error(data string) {
	cl.logger.error('${logger_prefix} data')
}

pub fn (mut cl NATSClient) listen() ! {
	t := spawn cl.websocket.listen()
	for cl.websocket.client_state.state == .open {
		cl.pull_messages(20, cl.pull_frequency)
		// keep connection alive
		cl.send_ping()
		time.sleep(cl.pull_frequency * time.second)
	}
	t.wait()!
}

pub fn new_natsclient(address string, ch_messages chan NATSMessage, ch_keyvalue chan NATSKeyValue, logger &log.Logger) !&NATSClient {
	mut ws := websocket.new_client(address, websocket.ClientOpt{}) or {
		return error('failed to create client for ${address}: ${err}')
	}
	mut natsmsgparser := NATSMessageParser{}
	uuid := rand.uuid_v4()
	mut client := NATSClient{
		uuid:          uuid
		myinbox:       'myinbox.${uuid}'
		address:       address
		logger:        unsafe { logger }
		websocket:     ws
		ch_messages:   ch_messages
		ch_keyvalue:   ch_keyvalue
		natsmsgparser: &natsmsgparser
	}
	natsmsgparser.on_nats_message = client.nats_message
	natsmsgparser.on_nats_info = client.nats_info
	natsmsgparser.on_nats_ping = client.send_pong
	natsmsgparser.on_nats_error = client.nats_error

	ws.on_message(client.on_message)
	ws.connect()!

	client.send_connect()
	// myinbox is used to get messages back for consumers (should be unique)
	client.subscribe('${client.myinbox}.>') or {
		client.logger.error('${logger_prefix} Failed to subscribe to our inbox')
	}

	return &client
}
