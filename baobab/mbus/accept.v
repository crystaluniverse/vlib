module mbus

import freeflowuniverse.crystallib.algo.secp256k1
import freeflowuniverse.crystallib.redisclient
import time

[params]
pub struct AcceptRPCArgs {
pub:
	address string // ipaddress or redis connection string
	// https://redis.io/topics/protocol
	// examples:
	//   localhost:6379
	//   /tmp/redis-default.sock
	conntype      ConnectionType
	twinid_source u32    // which twin has asked to get something
	twinid_exec   u32    // which twins need to receive and execute
	circle        u32    // unique on the exec twins (need to exist on each twin which needs to execute)
	action        string // e.g. cloud.vm_create
	msg           []u8   // bytestr
	timeout       u16    // seconds for timeout
	crypto        &secp256k1.Secp256k1
}

// send a message
pub fn send(args_ SendRPCArgs) ! {
	mut args := args_
	mut msg := RPCMessage{
		twinid_source: args.twinid_source
		twinid_exec: args.twinid_exec
		circle: args.circle
		action: args.action
		msg: args.msg
		time: now
		timeout: args.timeout
	}

	data := msg.encode() // TODO: need to see how to store bin data in redis, does it work as is?

	if conntype == .redis {
		mut r := redisclient.get(args.address)!
		r.hset('rpc.db', msg.rpc_id.hex(), data)!
		mut start := time.now().format() //"YYYY-MM-DD HH:mm" format (24h).
		activedata := '${start},${msg.timeout},1,N' // see readme.md
		r.hset('rpc.active.${msg.twinid_exec}', activedata)!
		r.lpush('rpc.processor.in', '${msg.twinid_exec},${msg.rpc_id.hex()}')!
	} else {
		panic('not implemented yet')
	}
}
