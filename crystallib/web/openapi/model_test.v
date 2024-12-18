module openapi

import os
import json
import freeflowuniverse.crystallib.data.jsonschema { Reference, Schema, SchemaRef }

const spec_path = '${os.dir(@FILE)}/testdata/openapi.json'
const spec_json = os.read_file(spec_path) or { panic(err) }

const spec = OpenAPI{
	openapi:    '3.0.3'
	info:       Info{
		title:       'Pet Store API'
		description: 'A sample API for a pet store'
		version:     '1.0.0'
	}
	servers:    [
		Server{
			url:         'https://api.petstore.example.com/v1'
			description: 'Production server'
		},
		Server{
			url:         'https://staging.petstore.example.com/v1'
			description: 'Staging server'
		},
	]
	paths:      {
		'/pets':             PathItem{
			get:  Operation{
				summary:      'List all pets'
				operation_id: 'listPets'
				parameters:   [
					Parameter{
						name:        'limit'
						in_:         'query'
						description: 'Maximum number of pets to return'
						required:    false
						schema:      Schema{
							typ:    'integer'
							format: 'int32'
						}
					},
				]
				responses:    {
					'200': Response{
						description: 'A paginated list of pets'
						content:     {
							'application/json': MediaType{
								schema: Reference{
									ref: '#/components/schemas/Pets'
								}
							}
						}
					}
					'400': Response{
						description: 'Invalid request'
					}
				}
			}
			post: Operation{
				summary:      'Create a new pet'
				operation_id: 'createPet'
				request_body: RequestBody{
					required: true
					content:  {
						'application/json': MediaType{
							schema: Reference{
								ref: '#/components/schemas/NewPet'
							}
						}
					}
				}
				responses:    {
					'201': Response{
						description: 'Pet created'
						content:     {
							'application/json': MediaType{
								schema: Reference{
									ref: '#/components/schemas/Pet'
								}
							}
						}
					}
					'400': Response{
						description: 'Invalid input'
					}
				}
			}
		}
		'/pets/{petId}':     PathItem{
			get:    Operation{
				summary:      'Get a pet by ID'
				operation_id: 'getPet'
				parameters:   [
					Parameter{
						name:        'petId'
						in_:         'path'
						description: 'ID of the pet to retrieve'
						required:    true
						schema:      Schema{
							typ:    'integer'
							format: 'int64'
						}
					},
				]
				responses:    {
					'200': Response{
						description: 'A pet'
						content:     {
							'application/json': MediaType{
								schema: Reference{
									ref: '#/components/schemas/Pet'
								}
							}
						}
					}
					'404': Response{
						description: 'Pet not found'
					}
				}
			}
			delete: Operation{
				summary:      'Delete a pet by ID'
				operation_id: 'deletePet'
				parameters:   [
					Parameter{
						name:        'petId'
						in_:         'path'
						description: 'ID of the pet to delete'
						required:    true
						schema:      Schema{
							typ:    'integer'
							format: 'int64'
						}
					},
				]
				responses:    {
					'204': Response{
						description: 'Pet deleted'
					}
					'404': Response{
						description: 'Pet not found'
					}
				}
			}
		}
		'/orders':           PathItem{
			get: Operation{
				summary:      'List all orders'
				operation_id: 'listOrders'
				responses:    {
					'200': Response{
						description: 'A list of orders'
						content:     {
							'application/json': MediaType{
								schema: Schema{
									typ:   'array'
									items: SchemaRef(Reference{
										ref: '#/components/schemas/Order'
									})
								}
							}
						}
					}
				}
			}
		}
		'/orders/{orderId}': PathItem{
			get:    Operation{
				summary:      'Get an order by ID'
				operation_id: 'getOrder'
				parameters:   [
					Parameter{
						name:        'orderId'
						in_:         'path'
						description: 'ID of the order to retrieve'
						required:    true
						schema:      Schema{
							typ:    'integer'
							format: 'int64'
						}
					},
				]
				responses:    {
					'200': Response{
						description: 'An order'
						content:     {
							'application/json': MediaType{
								schema: Reference{
									ref: '#/components/schemas/Order'
								}
							}
						}
					}
					'404': Response{
						description: 'Order not found'
					}
				}
			}
			delete: Operation{
				summary:      'Delete an order by ID'
				operation_id: 'deleteOrder'
				parameters:   [
					Parameter{
						name:        'orderId'
						in_:         'path'
						description: 'ID of the order to delete'
						required:    true
						schema:      Schema{
							typ:    'integer'
							format: 'int64'
						}
					},
				]
				responses:    {
					'204': Response{
						description: 'Order deleted'
					}
					'404': Response{
						description: 'Order not found'
					}
				}
			}
		}
		'/users':            PathItem{
			post: Operation{
				summary:      'Create a user'
				operation_id: 'createUser'
				request_body: RequestBody{
					required: true
					content:  {
						'application/json': MediaType{
							schema: Reference{
								ref: '#/components/schemas/NewUser'
							}
						}
					}
				}
				responses:    {
					'201': Response{
						description: 'User created'
						content:     {
							'application/json': MediaType{
								schema: Reference{
									ref: '#/components/schemas/User'
								}
							}
						}
					}
				}
			}
		}
	}
	components: Components{
		schemas: {
			'Pet':     SchemaRef(Schema{
				typ:        'object'
				required:   ['id', 'name']
				properties: {
					'id':   SchemaRef(Schema{
						typ:    'integer'
						format: 'int64'
					})
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
			})
			'NewPet':  SchemaRef(Schema{
				typ:        'object'
				required:   ['name']
				properties: {
					'name': SchemaRef(Schema{
						typ: 'string'
					})
					'tag':  SchemaRef(Schema{
						typ: 'string'
					})
				}
			})
			'Pets':    SchemaRef(Schema{
				typ:   'array'
				items: SchemaRef(Reference{
					ref: '#/components/schemas/Pet'
				})
			})
			'Order':   SchemaRef(Schema{
				typ:        'object'
				required:   ['id', 'petId', 'quantity', 'shipDate']
				properties: {
					'id':       SchemaRef(Schema{
						typ:    'integer'
						format: 'int64'
					})
					'petId':    SchemaRef(Schema{
						typ:    'integer'
						format: 'int64'
					})
					'quantity': SchemaRef(Schema{
						typ:    'integer'
						format: 'int32'
					})
					'shipDate': SchemaRef(Schema{
						typ:    'string'
						format: 'date-time'
					})
					'status':   SchemaRef(Schema{
						typ:   'string'
						enum_: ['placed', 'approved', 'delivered']
					})
					'complete': SchemaRef(Schema{
						typ: 'boolean'
					})
				}
			})
			'User':    SchemaRef(Schema{
				typ:        'object'
				required:   ['id', 'username']
				properties: {
					'id':       SchemaRef(Schema{
						typ:    'integer'
						format: 'int64'
					})
					'username': SchemaRef(Schema{
						typ: 'string'
					})
					'email':    SchemaRef(Schema{
						typ: 'string'
					})
					'phone':    SchemaRef(Schema{
						typ: 'string'
					})
				}
			})
			'NewUser': SchemaRef(Schema{
				typ:        'object'
				required:   ['username']
				properties: {
					'username': SchemaRef(Schema{
						typ: 'string'
					})
					'email':    SchemaRef(Schema{
						typ: 'string'
					})
					'phone':    SchemaRef(Schema{
						typ: 'string'
					})
				}
			})
		}
	}
}

pub fn testsuite_begin() {}

fn test_decode() {
	decoded := json_decode(spec_json)!

	assert decoded.openapi == spec.openapi
	assert decoded.info == spec.info
	assert decoded.servers == spec.servers
	for key, path in decoded.paths {
		assert path.ref == spec.paths[key].ref, 'Paths ${key} dont match.'
		assert path.summary == spec.paths[key].summary, 'Paths ${key} dont match.'
		assert path.description == spec.paths[key].description, 'Paths ${key} dont match.'
		match_operations(path.get, spec.paths[key].get)
		match_operations(path.put, spec.paths[key].put)
		match_operations(path.post, spec.paths[key].post)
		match_operations(path.delete, spec.paths[key].delete)
	}
	assert decoded.webhooks == spec.webhooks
	for key, schema in decoded.components.schemas {
		assert schema == spec.components.schemas[key], 'Schemas ${key} dont match.'
	}
	assert decoded.components == spec.components
	assert decoded.security == spec.security
}

fn test_encode() {
	spec.json_encode()
}

fn match_operations(a Operation, b Operation) {
	println(a.responses['200'].content['application/json'].schema)
	assert a.tags == b.tags, 'Tags do not match.'
	assert a.summary == b.summary, 'Summary does not match.'
	assert a.description == b.description, 'Description does not match.'
	assert a.external_docs == b.external_docs, 'External documentation does not match.'
	assert a.operation_id == b.operation_id, 'Operation ID does not match.'
	assert a.parameters == b.parameters, 'Parameters do not match.'
	assert a.request_body == b.request_body, 'Request body does not match.'
	assert a.responses == b.responses, 'Responses do not match.'
	assert a.callbacks == b.callbacks, 'Callbacks do not match.'
	assert a.deprecated == b.deprecated, 'Deprecated flag does not match.'
	assert a.security == b.security, 'Security requirements do not match.'
	assert a.servers == b.servers, 'Servers do not match.'
}
