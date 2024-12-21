module generator

import freeflowuniverse.crystallib.core.codemodel { Function, Param, Result, Struct, Type }
import freeflowuniverse.crystallib.rpc.openrpc

pub fn test_generate_openrpc() ! {
	actor := Actor{
		methods: [
			ActorMethod{
				func: Function{
					name: 'get_object'
					params: [
						Param{
							name: 'id'
							typ: Type{
								symbol: 'int'
							}
						},
					]
					result: Result{
						typ: Type{
							symbol: 'Object'
						}
					}
				}
			},
		]
		objects: [BaseObject{
			structure: Struct{
				name: 'Object'
			}
		}]
	}
	object := generate_openrpc(actor)
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
