module raft

import json

enum MessageType {
	vote_request
	vote_response
	append_entries
}

// We can use this function to get the byte representation of the message type
fn (mt MessageType) to_byte() byte {
	return byte(mt)
}

// And this function to convert a byte back to a MessageType
fn byte_to_message_type(b byte) ?MessageType {
	return MessageType(b)
}

fn encode_message[T](msg T) string {
	mut encoded := ''
	match typeof(msg).name {
		'VoteRequest' { encoded += MessageType.vote_request.to_byte().str() }
		'VoteResponse' { encoded += MessageType.vote_response.to_byte().str() }
		'AppendEntries' { encoded += MessageType.append_entries.to_byte().str() }
		else { panic('Unknown message type') }
	}
	encoded += json.encode(msg)
	return encoded
}

fn decode_message(encoded string) ?Message {
	if encoded.len < 1 {
		return error('Invalid encoded message')
	}

	msg_type := byte_to_message_type(encoded[0]) or { return error('Invalid message type') }
	json_str := encoded[1..]

	match msg_type {
		.vote_request { return json.decode(VoteRequest, json_str) }
		.vote_response { return json.decode(VoteResponse, json_str) }
		.append_entries { return json.decode(AppendEntries, json_str) }
	}
}
