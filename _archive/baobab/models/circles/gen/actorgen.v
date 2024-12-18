module main

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.core.codeparser
import os

pub struct GenerateActorParams {
	model_path string
}

pub fn generate_actor(params GenerateActorParams) !string {
	code := codeparser.parse_v(params.model_path)!

	structs := code.filter(it is codemodel.Struct).map(it as codemodel.Struct)
	functions := code.filter(it is codemodel.Function).map(it as codemodel.Function)
	handler := generate_handlers(functions)
	mut methods := []string{}
	for function in functions {
		params_structs := structs.filter(it.name == function.params[0].typ.symbol)
		if params_structs.len == 0 {
			return error('error')
		}
		methods << generate_actor_method(
			function:      function
			params_struct: params_structs[0]
		)
	}
	actor_code := $tmpl('templates/actor.v.template')
	return actor_code
}

pub fn generate_handlers(functions []codemodel.Function) string {
	handlers := functions.map('\'${it.name}\' { actor.${it.name}(action.params)! }')
	return $tmpl('templates/handler.v.template')
}

struct ActorMethodParams {
	function      codemodel.Function
	params_struct codemodel.Struct
}

pub fn generate_actor_method(params ActorMethodParams) string {
	function := params.function
	println(function)
	mut params_getters := []string{}
	for field in params.params_struct.fields {
		params_getters << '${field.name}:= params.get(\'${field.name}\')!'
	}

	mut method_params := []string{}
	for field in params.params_struct.fields {
		method_params << '${field.name}: ${field.name}'
	}
	method_call := if params.function.receiver.name != 'circle' {
		'circle.${params.function.receiver.name}.${params.function.name}(
			${method_params.join('\n')}
		)'
	} else {
		'circle.${params.function.name}(
			${method_params.join('\n')}
		)'
	}
	return $tmpl('templates/method.v.template')
}
