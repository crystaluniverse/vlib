module 



// AUTO-GENERATED FILE - DO NOT EDIT MANUALLY

pub struct OpenAPIHandler {
    mut:
        actor Actor
}

pub fn (mut h OpenAPIHandler) handle(req Request) !Response {
    match req.operation.operation_id {
        "listPets" {
            println("Handling listPets for listPets")
            response := h.actor.handle_listPets(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "createPet" {
            println("Handling createPet for createPet")
            response := h.actor.handle_createPet(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "getPet" {
            println("Handling getPet for getPet")
            response := h.actor.handle_getPet(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "deletePet" {
            println("Handling deletePet for deletePet")
            response := h.actor.handle_deletePet(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "listOrders" {
            println("Handling listOrders for listOrders")
            response := h.actor.handle_listOrders(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "getOrder" {
            println("Handling getOrder for getOrder")
            response := h.actor.handle_getOrder(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "deleteOrder" {
            println("Handling deleteOrder for deleteOrder")
            response := h.actor.handle_deleteOrder(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        "createUser" {
            println("Handling createUser for createUser")
            response := h.actor.handle_createUser(req.body) or {
                return Response{ status: http.Status.internal_server_error, body: "Internal server error: $err" }
            }
            return Response{ status: http.Status.ok, body: response }
        }
        else {
            return error("Unknown operation: ${req.operation.operation_id}")
        }
    }
}