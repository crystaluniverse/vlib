module mbus

import freeflowuniverse.crystallib.algo.secp256k1
import freeflowuniverse.crystallib.clients.redisclient
import time

pub enum ConnectionType {
	ipv6
	ipv4
	redis
}

@[params]
pub struct SendRPCArgs {
pub:
	address       string // ipaddress (if empty then will stay in local redis)
	circle        u32    // unique on the exec twins (need to exist on each twin which needs to execute)
	action        string // e.g. cloud.vm_create
	twinid_source u32    // which twin has asked to get something (source of rpc)
	twinid_exec   u32    // id of the twin which accepts the message for execution and payment
	msg           []u8   // bytestr (can be data or result, for acceptance is empty)
	timeout       u16    // seconds for timeout
	state         RPCState
	crypto        &secp256k1.Secp256k1
}

// send a message
pub fn send(args_ SendRPCArgs) ! {
	mut args := args_
	now_epoch := time.now().unix_time()
	mut msg := RPCMessage{
		twinid_source: args.twinid_source
		twinid_exec:   args.twinid_exec
		circle:        args.circle
		action:        args.action
		msg:           args.msg
		time:          now_epoch
		timeout:       args.timeout
		state:         args.state
	}

	data := msg.encode() // TODO: need to see how to store bin data in redis, does it work as is?

	mut r := redisclient.get(args.address)!
	r.hset('rpc.db', msg.rpc_id.hex(), data)!
	mut start := time.now().format() //"YYYY-MM-DD HH:mm" format (24h).

	if msg.state == .out {
		activedata := '${start},${msg.timeout},1,N' // see readme.md
		r.hset('rpc.active.${msg.twinid_exec}', activedata)!
		r.lpush('rpc.processor.in', '${msg.twinid_exec},${msg.rpc_id.hex()}')!
		if args.address.len > 0 && !r.exists('rpc.address.${msg.twinid_exec}') {
			r.set('rpc.address.${msg.twinid_exec}', args.address)!
			// TODO: put timeout on it
		}
	}
}
