module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.texttools
import os

pub fn (generator ActorGenerator) generate_handler_method(methods []codemodel.Function) codemodel.Function {
	if methods.len == 0 {
		panic('Generate handler requires at least 1 method')
	}
	handlers := methods.map('\'${it.name}\' { actor.${it.name}(action.params)! }')
	return codemodel.Function{
		name:     'act'
		receiver: codemodel.Param{
			name:      'actor'
			typ:       codemodel.Type{
				symbol: methods[0].receiver.typ.symbol // TODO: make more defensive, receiver must be same
			}
			is_shared: true
		}
		body:     handlers.join('\n')
		params:   [
			codemodel.Param{
				name: 'action'
				typ:  codemodel.Type{
					symbol: 'playbook.Action'
				}
			},
		]
	}
}
