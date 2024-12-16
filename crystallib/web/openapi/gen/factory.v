module gen

import freeflowuniverse.crystallib.core.codemodel { Module, Struct }
import freeflowuniverse.crystallib.core.texttools
import net.http

// configures client to be generated
pub struct ClientConfig {
	api_name string
	paths    []Path
	structs  []Struct
}

// HTTP API Paths
pub struct Path {
	operations []Operation
}

// HTTP Operations that can be done with a given path
pub struct Operation {
	name       string
	method     http.Method
	parameters []Parameter
	responses  map[string]Parameter // Params mapped by http response code
}

// API Call or Response parameter.
pub struct Parameter {
	codemodel.Param
	encoding ParameterEncoding
}

pub enum ParameterEncoding {
	path
}

struct APIClient {
}

pub fn generate_client_module(config ClientConfig) !Module {
	mut generator := ClientGenerator{
		api_name: texttools.name_fix(config.api_name)
		client_struct: Struct{
			name: '${config.api_name.title()}Client'
		}
	}
	return Module{
		name: '${config.api_name}_client'
		files: [
			generator.generate_factory(),
			generator.generate_client(),
			generator.generate_model(config.structs)!,
			generator.generate_methods(config.paths)!,
		]
	}
}
