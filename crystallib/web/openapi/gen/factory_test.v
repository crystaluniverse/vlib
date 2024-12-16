module gen

import freeflowuniverse.crystallib.core.codemodel

fn test_generate_client_module() {
	client_module := generate_client_module(
		api_name: 'testapi'
	)!

	assert client_module.name == 'testapi_client'
	assert client_module.files.len == 3
	assert client_module.files.map(it.name) == [
		'client',
		'model',
		'methods',
	]
}
