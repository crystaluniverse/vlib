## OpenAPI Code Generation Module


### Way structure definitions are written and arranged

Object schemas are defined in an OpenAPI Specification, which define the structure of data passed as parameters to a API Call, and data returned by the calls.

These schemas therefore require data structures that need to be defined as V `struct`s in code.

Object schemas defined in the components field of the OpenAPI Specification are assumed to be 'common' to API calls defined in the specification. The `struct`s representing these common object schemas are therefore defined in a `model.v` file. 

After that, the schemas defined in the path operations are generated alongside the Client API Methods they belong to.

`openapi.json`
```json
{
    "components": {
        "schemas": {
            "Person": {}
        }
    },
    "paths": {
        "/new_person": {
            "post": {
                "parameters": [
                    {
                        "name": "person_args",
                        "schema": {
                            "type": "object"
                        }
                    }
                ]
            }
        }
    }
}
```

`model.v`
```
struct Person{}
```

`methods.v`
```
struct NewPersonArgs {}

fn new_person(person_args NewPersonArgs) Person {}
```