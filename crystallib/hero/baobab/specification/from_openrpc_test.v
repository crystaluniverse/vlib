module specification

import freeflowuniverse.crystallib.core.codemodel { Struct, Function }
import freeflowuniverse.crystallib.rpc.openrpc { ContentDescriptor, Error }
import freeflowuniverse.crystallib.web.openapi { OpenAPI, Info, ServerSpec, Components, Operation, PathItem, PathRef }
import freeflowuniverse.crystallib.data.jsonschema {Schema, Reference, SchemaRef}

const openapi_spec = openapi.OpenAPI{
	openapi: '3.0.3'
	info: openapi.Info{
		title: 'Pet Store API'
		description: 'A sample API for a pet store'
		version: '1.0.0'
	}
	servers: [
		openapi.ServerSpec{
			url: 'https://api.petstore.example.com/v1'
			description: 'Production server'
		},
		openapi.ServerSpec{
			url: 'https://staging.petstore.example.com/v1'
			description: 'Staging server'
		}
	]
	paths: {
		'/pets': openapi.PathItem{
			get: openapi.Operation{
				summary: 'List all pets'
				operation_id: 'listPets'
				parameters: [
					openapi.Parameter{
						name: 'limit'
						in_: 'query'
						description: 'Maximum number of pets to return'
						required: false
						schema: Schema{
							typ: 'integer'
							format: 'int32'
						}
					}
				]
				responses: {
					'200': openapi.ResponseSpec{
						description: 'A paginated list of pets'
						content: {
							'application/json': openapi.MediaType{
								schema: Reference{
									ref: '#/components/schemas/Pets'
								}
							}
						}
					}
					'400': openapi.ResponseSpec{
						description: 'Invalid request'
					}
				}
			}
			post: openapi.Operation{
				summary: 'Create a new pet'
				operation_id: 'createPet'
				request_body: openapi.RequestBody{
					required: true
					content: {
						'application/json': openapi.MediaType{
							schema: Reference{
								ref: '#/components/schemas/NewPet'
							}
						}
					}
				}
				responses: {
					'201': openapi.ResponseSpec{
						description: 'Pet created'
						content: {
							'application/json': openapi.MediaType{
								schema: Reference{
									ref: '#/components/schemas/Pet'
								}
							}
						}
					}
					'400': openapi.ResponseSpec{
						description: 'Invalid input'
					}
				}
			}
		}
		'/pets/{petId}': openapi.PathItem{
			get: openapi.Operation{
				summary: 'Get a pet by ID'
				operation_id: 'getPet'
				parameters: [
					openapi.Parameter{
						name: 'petId'
						in_: 'path'
						description: 'ID of the pet to retrieve'
						required: true
						schema: Schema{
							typ: 'integer'
							format: 'int64'
						}
					}
				]
				responses: {
					'200': openapi.ResponseSpec{
						description: 'A pet'
						content: {
							'application/json': openapi.MediaType{
								schema: Reference{
									ref: '#/components/schemas/Pet'
								}
							}
						}
					}
					'404': openapi.ResponseSpec{
						description: 'Pet not found'
					}
				}
			}
			delete: openapi.Operation{
				summary: 'Delete a pet by ID'
				operation_id: 'deletePet'
				parameters: [
					openapi.Parameter{
						name: 'petId'
						in_: 'path'
						description: 'ID of the pet to delete'
						required: true
						schema: Schema{
							typ: 'integer'
							format: 'int64'
						}
					}
				]
				responses: {
					'204': openapi.ResponseSpec{
						description: 'Pet deleted'
					}
					'404': openapi.ResponseSpec{
						description: 'Pet not found'
					}
				}
			}
		}
		'/orders': openapi.PathItem{
			get: openapi.Operation{
				summary: 'List all orders'
				operation_id: 'listOrders'
				responses: {
					'200': openapi.ResponseSpec{
						description: 'A list of orders'
						content: {
							'application/json': openapi.MediaType{
								schema: Schema{
									typ: 'array'
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
		'/orders/{orderId}': openapi.PathItem{
			get: openapi.Operation{
				summary: 'Get an order by ID'
				operation_id: 'getOrder'
				parameters: [
					openapi.Parameter{
						name: 'orderId'
						in_: 'path'
						description: 'ID of the order to retrieve'
						required: true
						schema: Schema{
							typ: 'integer'
							format: 'int64'
						}
					}
				]
				responses: {
					'200': openapi.ResponseSpec{
						description: 'An order'
						content: {
							'application/json': openapi.MediaType{
								schema: Reference{
									ref: '#/components/schemas/Order'
								}
							}
						}
					}
					'404': openapi.ResponseSpec{
						description: 'Order not found'
					}
				}
			}
			delete: openapi.Operation{
				summary: 'Delete an order by ID'
				operation_id: 'deleteOrder'
				parameters: [
					openapi.Parameter{
						name: 'orderId'
						in_: 'path'
						description: 'ID of the order to delete'
						required: true
						schema: Schema{
							typ: 'integer'
							format: 'int64'
						}
					}
				]
				responses: {
					'204': openapi.ResponseSpec{
						description: 'Order deleted'
					}
					'404': openapi.ResponseSpec{
						description: 'Order not found'
					}
				}
			}
		}
		'/users': openapi.PathItem{
			post: openapi.Operation{
				summary: 'Create a user'
				operation_id: 'createUser'
				request_body: openapi.RequestBody{
					required: true
					content: {
						'application/json': openapi.MediaType{
							schema: Reference{
								ref: '#/components/schemas/NewUser'
							}
						}
					}
				}
				responses: {
					'201': openapi.ResponseSpec{
						description: 'User created'
						content: {
							'application/json': openapi.MediaType{
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
	components: openapi.Components{
	schemas: {
		'Pet': SchemaRef(Schema{
			typ: 'object'
			required: ['id', 'name']
			properties: {
				'id': SchemaRef(Schema{
					typ: 'integer'
					format: 'int64'
				})
				'name': SchemaRef(Schema{
					typ: 'string'
				})
				'tag': SchemaRef(Schema{
					typ: 'string'
				})
			}
		})
		'NewPet': SchemaRef(Schema{
			typ: 'object'
			required: ['name']
			properties: {
				'name': SchemaRef(Schema{
					typ: 'string'
				})
				'tag': SchemaRef(Schema{
					typ: 'string'
				})
			}
		})
		'Pets': SchemaRef(Schema{
			typ: 'array'
			items: SchemaRef(Reference{
				ref: '#/components/schemas/Pet'
			})
		})
		'Order': SchemaRef(Schema{
			typ: 'object'
			required: ['id', 'petId', 'quantity', 'shipDate']
			properties: {
				'id': SchemaRef(Schema{
					typ: 'integer'
					format: 'int64'
				})
				'petId': SchemaRef(Schema{
					typ: 'integer'
					format: 'int64'
				})
				'quantity': SchemaRef(Schema{
					typ: 'integer'
					format: 'int32'
				})
				'shipDate': SchemaRef(Schema{
					typ: 'string'
					format: 'date-time'
				})
				'status': SchemaRef(Schema{
					typ: 'string'
					enum_: ['placed', 'approved', 'delivered']
				})
				'complete': SchemaRef(Schema{
					typ: 'boolean'
				})
			}
		})
		'User': SchemaRef(Schema{
			typ: 'object'
			required: ['id', 'username']
			properties: {
				'id': SchemaRef(Schema{
					typ: 'integer'
					format: 'int64'
				})
				'username': SchemaRef(Schema{
					typ: 'string'
				})
				'email': SchemaRef(Schema{
					typ: 'string'
				})
				'phone': SchemaRef(Schema{
					typ: 'string'
				})
			}
		})
		'NewUser': SchemaRef(Schema{
			typ: 'object'
			required: ['username']
			properties: {
				'username': SchemaRef(Schema{
					typ: 'string'
				})
				'email': SchemaRef(Schema{
					typ: 'string'
				})
				'phone': SchemaRef(Schema{
					typ: 'string'
				})
			}
		})
	}
}
}

const actor_spec = specification.ActorSpecification{
    name: 'Pet Store API'
    description: 'A sample API for a pet store'
    interfaces: [.openapi]
    methods: [
        specification.ActorMethod{
            name: 'listPets'
            summary: 'List all pets'
            parameters: [
                openrpc.ContentDescriptor{
                    name: 'limit'
                    summary: 'Maximum number of pets to return'
                    description: 'Maximum number of pets to return'
                    schema: jsonschema.SchemaRef(jsonschema.Schema{
                        typ: 'integer'
                        format: 'int32'
                    })
                }
            ]
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
                schema: jsonschema.SchemaRef(jsonschema.Reference{
                    ref: '#/components/schemas/Pets'
                })
            }
            errors: [
                openrpc.Error{
                    code: 400
                    message: 'Invalid request'
                }
            ]
        },
        specification.ActorMethod{
            name: 'createPet'
            summary: 'Create a new pet'
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
            }
            errors: [
                openrpc.Error{
                    code: 400
                    message: 'Invalid input'
                }
            ]
        },
        specification.ActorMethod{
            name: 'getPet'
            summary: 'Get a pet by ID'
            parameters: [
                openrpc.ContentDescriptor{
                    name: 'petId'
                    summary: 'ID of the pet to retrieve'
                    description: 'ID of the pet to retrieve'
                    schema: jsonschema.SchemaRef(jsonschema.Schema{
                        typ: 'integer'
                        format: 'int64'
                    })
                }
            ]
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
                schema: jsonschema.SchemaRef(jsonschema.Reference{
                    ref: '#/components/schemas/Pet'
                })
            }
            errors: [
                openrpc.Error{
                    code: 404
                    message: 'Pet not found'
                }
            ]
        },
        specification.ActorMethod{
            name: 'deletePet'
            summary: 'Delete a pet by ID'
            parameters: [
                openrpc.ContentDescriptor{
                    name: 'petId'
                    summary: 'ID of the pet to delete'
                    description: 'ID of the pet to delete'
                    schema: jsonschema.SchemaRef(jsonschema.Schema{
                        typ: 'integer'
                        format: 'int64'
                    })
                }
            ]
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
            }
            errors: [
                openrpc.Error{
                    code: 404
                    message: 'Pet not found'
                }
            ]
        },
        specification.ActorMethod{
            name: 'listOrders'
            summary: 'List all orders'
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
                schema: jsonschema.SchemaRef(jsonschema.Schema{
                    typ: 'array'
                    items: jsonschema.Items(jsonschema.SchemaRef(jsonschema.Reference{
                        ref: '#/components/schemas/Order'
                    }))
                })
            }
        },
        specification.ActorMethod{
            name: 'getOrder'
            summary: 'Get an order by ID'
            parameters: [
                openrpc.ContentDescriptor{
                    name: 'orderId'
                    summary: 'ID of the order to retrieve'
                    description: 'ID of the order to retrieve'
                    schema: jsonschema.SchemaRef(jsonschema.Schema{
                        typ: 'integer'
                        format: 'int64'
                    })
                }
            ]
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
                schema: jsonschema.SchemaRef(jsonschema.Reference{
                    ref: '#/components/schemas/Order'
                })
            }
            errors: [
                openrpc.Error{
                    code: 404
                    message: 'Order not found'
                }
            ]
        },
        specification.ActorMethod{
            name: 'deleteOrder'
            summary: 'Delete an order by ID'
            parameters: [
                openrpc.ContentDescriptor{
                    name: 'orderId'
                    summary: 'ID of the order to delete'
                    description: 'ID of the order to delete'
                    schema: jsonschema.SchemaRef(jsonschema.Schema{
                        typ: 'integer'
                        format: 'int64'
                    })
                }
            ]
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
            }
            errors: [
                openrpc.Error{
                    code: 404
                    message: 'Order not found'
                }
            ]
        },
        specification.ActorMethod{
            name: 'createUser'
            summary: 'Create a user'
            result: openrpc.ContentDescriptor{
                name: 'result'
                description: 'The response of the operation.'
            }
        }
    ]
    objects: [
        specification.BaseObject{
            structure: codemodel.Struct{
                name: 'Pet'
            }
        },
        specification.BaseObject{
            structure: codemodel.Struct{
                name: 'NewPet'
            }
        },
        specification.BaseObject{
            structure: codemodel.Struct{
                name: 'Pets'
            }
        },
        specification.BaseObject{
            structure: codemodel.Struct{
                name: 'Order'
            }
        },
        specification.BaseObject{
            structure: codemodel.Struct{
                name: 'User'
            }
        },
        specification.BaseObject{
            structure: codemodel.Struct{
                name: 'NewUser'
            }
        }
    ]
}

pub fn test_from_openapi() ! {
	assert from_openapi(openapi_spec)! == actor_spec
}