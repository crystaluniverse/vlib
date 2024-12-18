module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.texttools
import os

fn test_generate_handler_method() {
	test_generator := ActorGenerator{'test'}

	test_methods := [
		codemodel.Function{
			name:     'test_func1'
			receiver: codemodel.Param{
				name: 'test_actor'
				typ:  codemodel.Type{
					symbol: 'TestActor'
				}
			}
		},
		codemodel.Function{
			name:     'test_func2'
			receiver: codemodel.Param{
				name: 'test_actor'
				typ:  codemodel.Type{
					symbol: 'TestActor'
				}
			}
		},
	]

	handler := test_generator.generate_handler_method(test_methods)
	println(handler.vgen())
	panic('aaa')
}
