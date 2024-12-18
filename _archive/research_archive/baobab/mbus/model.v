module mbus

import freeflowuniverse.crystallib.data.paramsparser
import freeflowuniverse.crystallib.algo.encoder
import freeflowuniverse.crystallib.algo.secp256k1
import crypto.md5
import time

// mycelium rpc message = a reliable rpc message  (remote procedure call)
pub struct RPCMessage {
pub mut:
	circle u32    // unique on the exec twins (need to exist on each twin which needs to execute)
	action string // e.g. cloud.vm_create

	twinid_source u32 // which twin has asked to get something (source of rpc)
	twinid_exec   u32 // id of the twin which accepts the message for execution and payment

	msg     []u8 // bytestr (can be data or result, for acceptance is empty)
	time    u64  // time when it was send
	timeout u16  // seconds for timeout	
	state   RPCState
	// is hash of above encoded
	rpc_id    []u8 // unique on the source twin, where the rpc comes from, is hash
	return_id []u8 // unique for the return path, is hash of return message (can be result or acceptance)

	signature []u8 // signature using private key on source twin
}

pub enum RPCState {
	out
	acceptance
	result
	error
}

// does encoding
pub fn (mut msg RPCMessage) encode(crypto secp256k1.Secp256k1) []u8 {
	mut e := encoder.new()
	e.add_u32(msg.circle)
	e.add_string(msg.action)
	e.add_u32(msg.twinid_source)
	e.add_u32(msg.twinid_exec)
	e.add_u8(int(msg.state))

	e.add_bytes(msg.msg)
	e.add_u64(msg.time)
	e.add_u16(msg.timeout)

	hash_md5 := md5.sum(e.data)

	if msg.state == .out {
		msg.rpc_id = hash_md5
	} else {
		msg.return_id = hash_md5
	}

	e.add_bytes(msg.rpc_id) // now add this md5 to it
	e.add_bytes(msg.return_id)

	msg.signature = crypto.sign_data(hash_md5) // its enough to sign the md5
	e.add_bytes(msg.signature) // now add this md5 to it
	return e.data // is the encoded data
}

// go from binary form to RPCmessage
pub fn decode(data []u8) !RPCMessage {
	mut msg := RPCMessage{
		data: data
	}

	mut e := encoder.new()
	// TODO: decode
	if !msg.verify() {
		return error('cannot decode rpc message, data signature could not be verified. MSG ID:${msg.rpc_id}')
	}
	return RPCMessage{}
}

// verify using a pubkey
pub fn (mut msg RPCMessage) verify(pubkey []u8) ! {
	// TODO: verify the signature based on the source sender
	// start from msg.data
}
