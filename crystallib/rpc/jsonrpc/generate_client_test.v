module jsonrpc

import freeflowuniverse.crystallib.core.codemodel { Function, Param, Result, Struct, Type }

pub fn test_generate_client_factory() ! {
	factory_file := generate_client_factory('TestJsonRpcClient')
	assert factory_file.items.len == 3
	assert factory_file.items[0] is Struct
}

pub fn test_generate_client_method() ! {
	client_struct := generate_client_struct('TestJsonRpcClient')
	test_method := Function{
		name:   'test_jsonrpc_call'
		params: [Param{
			name: 'key'
			typ:  Type{
				symbol: 'string'
			}
		}]
		result: Result{
			name: 'result'
			typ:  Type{
				symbol: 'string'
			}
		}
	}
	client_method := generate_client_method(client_struct, test_method)!
	assert client_method.name == test_method.name
	assert client_method.receiver.name == 'client'
	assert client_method.receiver.typ.symbol == 'TestJsonRpcClient'
}
