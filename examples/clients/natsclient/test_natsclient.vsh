#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.crystallib.clients.natsclient
import log
import flag
import os
import time

const log_prefix = '[MAIN ]'

fn process_messages(ch_receive_message chan natsclient.NATSMessage, mut client natsclient.NATSClient, mut logger log.Logger) {
	for !ch_receive_message.closed {
		select {
			msg := <-ch_receive_message {
				// do something with the message here
				logger.info('${log_prefix} new message ${msg.message}')
				client.ack_message(msg.reply_to)
				logger.debug('${log_prefix} ACK message ${msg.sid} from subject ${msg.subject}')
			}
		}
	}
}

mut fp := flag.new_flag_parser(os.args)
fp.application('Example natsclient')
fp.limit_free_args(0, 0)!
fp.description('')
fp.skip_executable()
debug_log := fp.bool('debug', 0, false, 'log debug messages too')
_ := fp.finalize() or {
	eprintln(err)
	println(fp.usage())
	return
}

ch_receive_message := chan natsclient.NATSMessage{}
ch_receive_keyvalues := chan natsclient.NATSKeyValue{}
mut logger := log.Logger(&log.Log{
	level: if debug_log { .debug } else { .info }
})
mut client := natsclient.new_natsclient('ws://127.0.0.1:8880', ch_receive_message, ch_receive_keyvalues,
	&logger) or {
	logger.error(err.msg())
	return
}

client.create_stream('mystream', ['ORDERS.*']) or {
	logger.error('${err}')
	return
}

client.create_consumer('myconsumer', 'mystream', 'This is a consumer for the stream mystream') or {
	logger.error('${err}')
	return
}

t_process_messages := spawn process_messages(ch_receive_message, mut client, mut &logger)
t_listen := spawn client.listen()

store := 'mykeyvaluestore'
client.create_keyvalue_store(store) or {
	logger.error('${err}')
	return
}
client.add_keyvalue(store, 'key1', 'MODIFIED') or {
	logger.error('${err}')
	return
}
client.add_keyvalue(store, 'key5', 'MODIFIED') or {
	logger.error('${err}')
	return
}
client.get_value(store, 'key1') or {
	logger.error('${err}')
	return
}

select {
	keyval := <-ch_receive_keyvalues {
		logger.info('GOT KEY VALUE: ${keyval}')
	}
}

t_process_messages.wait()
ch_receive_message.close()
ch_receive_keyvalues.close()
t_listen.wait() or { logger.error('${err}') }
