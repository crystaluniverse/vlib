module code

import freeflowuniverse.crystallib.core.codemodel { Function, Param, Result, Struct, Type }
import freeflowuniverse.crystallib.rpc.openrpc
import os

const actor_name = 'testactor'
const actor_path = '${os.dir(@FILE)}/testdata/${actor_name}'

pub fn test_generate_openrpc() ! {
	actor := read(actor_path)!
	object := actor.generate_openrpc()
	panic(object.encode()!)
}

// pub fn param_to_content_descriptor(param Param) openrpc.ContentDescriptor {
// 	if param.name == 'id' && param.typ.symbol ==

// 	return openrpc.ContentDescriptor {
// 		name: param.name
// 		summary: param.description
// 		required: param.is_required()
// 		schema:
// 	}
// }
