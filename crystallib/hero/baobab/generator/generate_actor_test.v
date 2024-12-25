module generator

import freeflowuniverse.crystallib.core.codemodel
import freeflowuniverse.crystallib.hero.baobab.specification
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.pathlib
import os

const actor_spec = specification.ActorSpecification{
    name: 'Pet Store'
    description: 'A sample API for a pet store'
	interfaces: [.openrpc, .command]
    methods: [specification.ActorMethod{
        name: 'listPets'
        description: 'List all pets'
        func: codemodel.Function{
            name: 'listPets'
            params: [codemodel.Param{
                description: 'Maximum number of pets to return'
                name: 'limit'
                typ: codemodel.Type{
                    symbol: 'int'
                }
            }]
        }
    }, specification.ActorMethod{
        name: 'createPet'
        description: 'Create a new pet'
        func: codemodel.Function{
            name: 'createPet'
        }
    }, specification.ActorMethod{
        name: 'getPet'
        description: 'Get a pet by ID'
        func: codemodel.Function{
            name: 'getPet'
            params: [codemodel.Param{
                required: true
                description: 'ID of the pet to retrieve'
                name: 'petId'
                typ: codemodel.Type{
                    symbol: 'int'
                }
            }]
        }
    }, specification.ActorMethod{
        name: 'deletePet'
        description: 'Delete a pet by ID'
        func: codemodel.Function{
            name: 'deletePet'
            params: [codemodel.Param{
                required: true
                description: 'ID of the pet to delete'
                name: 'petId'
                typ: codemodel.Type{
                    symbol: 'int'
                }
            }]
        }
    }, specification.ActorMethod{
        name: 'listOrders'
        description: 'List all orders'
        func: codemodel.Function{
            name: 'listOrders'
        }
    }, specification.ActorMethod{
        name: 'getOrder'
        description: 'Get an order by ID'
        func: codemodel.Function{
            name: 'getOrder'
            params: [codemodel.Param{
                required: true
                description: 'ID of the order to retrieve'
                name: 'orderId'
                typ: codemodel.Type{
                    symbol: 'int'
                }
            }]
        }
    }, specification.ActorMethod{
        name: 'deleteOrder'
        description: 'Delete an order by ID'
        func: codemodel.Function{
            name: 'deleteOrder'
            params: [codemodel.Param{
                required: true
                description: 'ID of the order to delete'
                name: 'orderId'
                typ: codemodel.Type{
                    symbol: 'int'
                }
            }]
        }
    }, specification.ActorMethod{
        name: 'createUser'
        description: 'Create a user'
        func: codemodel.Function{
            name: 'createUser'
        }
    }]
    objects: [specification.BaseObject{
        structure: codemodel.Struct{
            name: 'Pet'
        }
    }, specification.BaseObject{
        structure: codemodel.Struct{
            name: 'NewPet'
        }
    }, specification.BaseObject{
        structure: codemodel.Struct{
            name: 'Pets'
        }
    }, specification.BaseObject{
        structure: codemodel.Struct{
            name: 'Order'
        }
    }, specification.BaseObject{
        structure: codemodel.Struct{
            name: 'User'
        }
    }, specification.BaseObject{
        structure: codemodel.Struct{
            name: 'NewUser'
        }
    }]
}

const destination = '${os.dir(@FILE)}/testdata'

fn test_generate_actor_module() {
	actor_module := generate_actor_module(actor_spec)!
	actor_module.write(destination, 
        format: true
        overwrite: true
    )!
}
