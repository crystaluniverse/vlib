module gen

import net.http
import freeflowuniverse.crystallib.core.codemodel { CodeFile, CodeItem, Struct, Type }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console

pub struct ClientGenerator {
	api_name      string // name of the api the client is being generated for
	client_struct Struct // the structure representing the API Client, receiver of API Call methods.
pub mut:
	generated_structs []Struct
	generated_methods []string
}

fn (mut gen ClientGenerator) generate_client() CodeFile {
	return CodeFile{
		name: 'client'
		mod: '${gen.api_name}_client'
		imports: []
		items: [gen.client_struct]
	}
}

fn (mut gen ClientGenerator) generate_client_struct() Struct {
	return Struct{
		name: '${texttools.name_fix_snake_to_pascal(gen.api_name)}Client'
		is_pub: true
		generics: {
			'T': ''
		}
		embeds: [
			Struct{
				name: 'Base'
				mod: 'freeflowuniverse.crystallib.core.base'
				generics: {
					'T': ''
				}
			},
		]
		fields: [
			codemodel.StructField{
				name: 'connection'
				is_mut: true
				structure: Struct{
					name: 'HTTPConnection'
					mod: 'freeflowuniverse.crystallib.clients.httpconnection'
				}
				is_ref: true
			},
		]
	}
}

fn generate_client_config() Struct {
	return Struct{
		name: 'Config'
		embeds: [
			Struct{
				name: 'ConfigBase'
				mod: 'freeflowuniverse.crystallib.core.base'
				generics: {
					'T': ''
				}
			},
		]
		fields: [
			codemodel.StructField{
				name: 'url'
				typ: Type{
					symbol: 'string'
				}
			},
		]
	}
}

fn (mut gen ClientGenerator) generate_factory() CodeFile {
	client_name := texttools.name_fix(gen.api_name)
	client_struct := gen.generate_client_struct()
	config_struct := generate_client_config()
	get_function := gen.generate_get_function(client_struct)
	heroplay_function := gen.heroplay_function(client_struct)
	config_interactive_function := gen.config_interactive_function(client_struct)

	return CodeFile{
		name: 'factory'
		mod: '${gen.api_name}_client'
		imports: []
		items: [gen.client_struct]
		content: $tmpl('./templates/factory.v')
	}
}

fn (mut gen ClientGenerator) generate_get_function(client Struct) codemodel.Function {
	return codemodel.Function{
		name: 'get'
		params: [
			codemodel.Param{
				name: 'args'
				struct_: Struct{
					name: 'PlayArgs'
					mod: 'freeflowuniverse.crystallib.core.base'
					generics: {
						'': 'Config'
					}
				}
			},
		]
		result: codemodel.Result{
			structure: Struct{
				...client
				generics: {
					'': 'Config'
				}
			}
		}
		is_pub: true
		body: 'mut client := ${client.name}[Config]{}
	client.init(args)!
	return client'
	}
}

fn (mut gen ClientGenerator) heroplay_function(config Struct) codemodel.Function {
	return codemodel.Function{
		name: 'heroplay'
		params: [
			codemodel.Param{
				name: 'args'
				struct_: Struct{
					name: 'PlayBookAddArgs'
					mod: 'freeflowuniverse.crystallib.core.base'
				}
			},
		]
		result: codemodel.Result{
			result: true
		}
		is_pub: true
		body: "	// make session for configuring from heroscript
	mut session := play.session_new(session_name: 'config')!
	session.playbook_add(path: args.path, text: args.text, git_url: args.git_url)!
	for mut action in session.plbook.find(filter: '${gen.api_name}_client.define')! {
		mut p := action.params
		instance := p.get_default('instance', 'default')!
		mut cl := get(instance: instance)!
		mut cfg := cl.config()!
		mut config := p.decode[T]()!
		cl.config_save()!
	}"
	}
}

fn (mut gen ClientGenerator) config_interactive_function(client Struct) codemodel.Function {
	return codemodel.Function{
		name: 'config_interactive'
		receiver: codemodel.Param{
			name: 'self'
			mutable: true
			struct_: client
		}
		result: codemodel.Result{
			result: true
		}
		is_pub: true
		body: "mut myui := ui.new()!
	console.clear()
	console.print_debug('\n## Configure B2 Client')
	console.print_debug('========================\n\n')

	mut cfg := self.config()!

	self.instance = myui.ask_question(
		question: 'name for B2 (backblaze) client'
		default: self.instance
	)!

	cfg.description = myui.ask_question(
		question: 'description'
		minlen: 0
		default: cfg.description
	)!
	cfg.keyid = myui.ask_question(
		question: 'keyid e.g. 003e2a7be6357fb0000000001'
		minlen: 5
		default: cfg.keyid
	)!

	cfg.appkey = myui.ask_question(
		question: 'appkey e.g. K008UsdrYOAou2ulBHA8p4KBe/dL2n4'
		minlen: 5
		default: cfg.appkey
	)!

	buckets := self.list_buckets()!
	bucket_names := buckets.map(it.name)

	cfg.bucketname = myui.ask_dropdown(
		question: 'choose default bucket name'
		items: bucket_names
	)!

	self.config_save()!"
	}
}

fn (mut gen ClientGenerator) generate_model(structs []Struct) !CodeFile {
	return CodeFile{
		name: 'model'
		mod: '${gen.api_name}_client'
		items: structs.map(CodeItem(it))
	}
}

fn (mut gen ClientGenerator) generate_methods(paths []Path) !CodeFile {
	mut code := []CodeItem{}
	for path in paths {
		for operation in path.operations {
			structs := operation.parameters.map(it.Param.struct_)
			to_generate := structs.filter(it !in gen.generated_structs)
			code << gen.generate_method_structs(to_generate)
			code << gen.generate_client_method()!
		}
	}
	return CodeFile{
		name: 'methods'
		items: code
	}
}

fn (mut gen ClientGenerator) generate_method_structs(structs []Struct) []Struct {
	gen.generated_structs << structs
	return structs
}

@[params]
pub struct ClientMethodConfig {
	receiver   codemodel.Param
	name       string // name of method
	parameters []Parameter
	responses  map[string]Parameter // Params mapped by http response code
	method     http.Method
}

// generate_client_call generates a client method and accompanying necessary
pub fn (mut gen ClientGenerator) generate_client_method(config ClientMethodConfig) !codemodel.Function {
	// http_request :=

	if '200' !in config.responses {
		return error('At least one response should have a 200 http code')
	}

	result_struct := config.responses['200'].struct_

	result := codemodel.Result{
		name: result_struct.name
		structure: config.responses['200'].Param.struct_
		typ: Type{
			symbol: result_struct.name
		}
	}

	return codemodel.Function{
		name: config.name
		receiver: config.receiver
		params: config.parameters.map(it.Param)
		result: result
	}
}
