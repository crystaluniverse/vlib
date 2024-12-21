module pet_store_actor



// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY

pub struct OpenAPIHandler {
    mut:
        actor Actor
}

pub fn (mut h OpenAPIHandler) handle(req Request) !Response {
    match req.operation.operation_id {
        "listPets" {
            response := h.actor.handle_list_pets(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "createPet" {
            response := h.actor.handle_create_pet(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "getPet" {
            response := h.actor.handle_get_pet(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "deletePet" {
            response := h.actor.handle_delete_pet(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "listOrders" {
            response := h.actor.handle_list_orders(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "getOrder" {
            response := h.actor.handle_get_order(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "deleteOrder" {
            response := h.actor.handle_delete_order(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "createUser" {
            response := h.actor.handle_create_user(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: ${err}" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        else {
            return error("Unknown operation: ${req.operation.operation_id}")
        }
    }
}
// Handler for list_pets
fn (mut actor Actor) handle_list_pets(data string) !string {
    params := json.decode(int, data) or { return error("Invalid input data: ${err}") }
    result := actor.list_pets(params)
    return json.encode(result)
}
// Handler for create_pet
fn (mut actor Actor) handle_create_pet(data string) !string {
    result := actor.create_pet()
    return json.encode(result)
}
// Handler for get_pet
fn (mut actor Actor) handle_get_pet(data string) !string {
    params := json.decode(int, data) or { return error("Invalid input data: ${err}") }
    result := actor.get_pet(params)
    return json.encode(result)
}
// Handler for delete_pet
fn (mut actor Actor) handle_delete_pet(data string) !string {
    params := json.decode(int, data) or { return error("Invalid input data: ${err}") }
    result := actor.delete_pet(params)
    return json.encode(result)
}
// Handler for list_orders
fn (mut actor Actor) handle_list_orders(data string) !string {
    result := actor.list_orders()
    return json.encode(result)
}
// Handler for get_order
fn (mut actor Actor) handle_get_order(data string) !string {
    params := json.decode(int, data) or { return error("Invalid input data: ${err}") }
    result := actor.get_order(params)
    return json.encode(result)
}
// Handler for delete_order
fn (mut actor Actor) handle_delete_order(data string) !string {
    params := json.decode(int, data) or { return error("Invalid input data: ${err}") }
    result := actor.delete_order(params)
    return json.encode(result)
}
// Handler for create_user
fn (mut actor Actor) handle_create_user(data string) !string {
    result := actor.create_user()
    return json.encode(result)
}