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

## OpenAPI Handler Generator

This project provides a utility to generate VLang handler functions and a main routing function based on an OpenAPI specification. It simplifies server-side integration by automatically creating boilerplate code for handling requests and mapping them to business logic.

### Features

- **Automatic Handler Generation:** Generates individual handlers for each operation in the OpenAPI spec.
- **Main Router Function:** Creates a centralized function to route incoming requests based on operation IDs.
- **Error Handling:** Includes basic error handling for invalid input and unrecognized operations.
- **Customizable Output:** Easily extendable to handle query parameters, headers, and more.

### How It Works

1. Parse the OpenAPI specification.
2. For each path and operation in the spec:
   - Generate an individual handler function.
   - Add a corresponding case in the main routing function.
3. Combine everything into a single V file for easy integration.

#### Example Workflow

1. **Input:** Provide an OpenAPI spec (e.g., `petstore.yaml`).
2. **Generated Output:**

   - **Individual Operation Handlers:**
     ```v
     fn (mut actor Actor) handle_listPets(data string) !string {
         println('Handling listPets with data: $data')
         params := json.decode(ListPetParams, data) or { return error("Invalid input data: $err") }
         result := actor.data_store.list_pets(params)
         return json.encode(result)
     }
     ```

   - **Main Routing Function:**
     ```v
     pub fn (mut h OpenAPIHandler) handle(req Request) !Response {
         match req.operation.operation_id {
             "listPets" {
                 println("Handling listPets for GET /pets")
                 response := h.actor.handle_listPets(req.body) or {
                     return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
                 }
                 return Response{ status: http.Status.ok, body: response }
             }
             else {
                 return error("Unknown operation: ${req.operation.operation_id}")
             }
         }
     }
     ```

### Usage

#### Input Requirements

- **OpenAPI Specification**: A valid OpenAPI 3.0 specification, either in JSON or YAML format.
- **V Structs**: Ensure that parameter and schema structs (e.g., `ListPetParams`, `NewPet`) are defined in your project.

#### Example Code to Generate Handlers

```v
import your_openapi_parser_module

fn main() {
    spec := your_openapi_parser_module.parse('path/to/openapi.yaml')!
    generated_code := openapi_to_handler_file(spec)
    os.write_file('generated_handlers.v', generated_code) or { panic(err) }
    println('Handlers successfully generated!')
}