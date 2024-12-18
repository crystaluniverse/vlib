module jsonrpc

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.ui.console

const receiver = codemodel.Struct{
	name: 'Tester'
}
const methods = [
	codemodel.Function{
		name:   'test_notification_method'
		params: [
			codemodel.Param{
				name: 'key'
				typ:  codemodel.Type{
					symbol: 'string'
				}
			},
		]
	},
	codemodel.Function{
		name:   'test_invocation_method'
		result: codemodel.Result{
			name: 'value'
			typ:  codemodel.Type{
				symbol: 'string'
			}
		}
	},
	codemodel.Function{
		name:   'test_method'
		params: [
			codemodel.Param{
				name: 'key'
				typ:  codemodel.Type{
					symbol: 'string'
				}
			},
		]
		result: codemodel.Result{
			name: 'value'
			typ:  codemodel.Type{
				symbol: 'string'
			}
		}
	},
	codemodel.Function{
		name:   'test_method_structs'
		params: [
			codemodel.Param{
				name: 'key_struct'
				typ:  codemodel.Type{
					symbol: 'Key'
				}
			},
		]
		result: codemodel.Result{
			name: 'value_struct'
			typ:  codemodel.Type{
				symbol: 'Value'
			}
		}
	},
]

fn test_method_to_call() ! {
	_ := method_to_call(codemodel.Function{})
}

pub fn test_generate_handler() ! {
	handler_code := generate_handler(
		receiver: receiver
		methods:  methods
	)!

	v_code := codemodel.vgen(handler_code)
	console.print_debug(v_code)
}
