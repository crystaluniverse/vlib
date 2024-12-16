module gen

// // import net.http
// // import freeflowuniverse.crystallib.core.openapi
// // import freeflowuniverse.crystallib.core.codemodel

// pub fn generate_client(spec openapi.OpenAPI) codemodel.Module {
// 	for key, path in spec.paths {
// 		generate_path(
// 			name: key
// 			path: path
// 		)
// 	}

// 	paths := spec.paths.values().map(

// 		Path{operations: it.operations.map()}
// 	)

// 	client_module := generate_client_module(
// 		api_name: 'testapi'
// 		paths
// 	)!
// }

// pub struct PathParams {
// 	name string
// 	path openapi.Path
// }

// pub fn generate_path(params PathParams) Path {

// 	mut operations := []Operation{}

// 	supported_methods := ['get', 'put', 'post', 'delete']
// 	$for field in PathItem {
// 		if field.name in supported_methods {
// 			value := params.path.($field.name)
// 			if '${value}' != 'Option(none)' {
// 				operations << Operation {
// 					name: '${params.name}_${field.name}'
// 					method: field.name
// 					parameters: value.parameters.map(
// 						Parameter{
// 							name: it.name
// 							description: it.description
// 						}
// 					)
// 				}
// 			}

// 		}
// 	}

// 	return Path {
// 		operations: params.path.

// 		[
// 			Operation {
// 				name: params.name
// 				method:
// 			}
// 		]
// 	}
// 	path.
// }
