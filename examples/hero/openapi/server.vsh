#!/usr/bin/env -S v -w -n -enable-globals run

import os
import time
import veb
import json
import x.json2 {Any}
import net.http
import freeflowuniverse.crystallib.data.jsonschema {Schema}
import freeflowuniverse.crystallib.web.openapi {Server, Context, Request, Response}
import freeflowuniverse.crystallib.hero.processor {Processor, ProcedureCall, ProcedureResponse, ProcessParams}
import freeflowuniverse.crystallib.clients.redisclient

const spec_path = '${os.dir(@FILE)}/data/openapi.json'
const spec_json = os.read_file(spec_path) or { panic(err) }

// Main function to start the server
fn main() {
    // Initialize the Redis client and RPC mechanism
    mut redis := redisclient.new('localhost:6379')!
    mut rpc := redis.rpc_get('procedure_queue')

    // Initialize the server
    mut server := &Server{
        specification: openapi.json_decode(spec_json)!
        handler: Handler{
            processor: Processor{
                rpc: rpc
            }
        }
    }

    // Start the server
    veb.run[Server, Context](mut server, 8080)
}

pub struct Handler {
    mut:
        processor Processor
}

fn (mut handler Handler) handle(request Request) !Response {
    // Convert incoming OpenAPI request to a procedure call
    mut params := []string{}

    if request.arguments.len > 0 {
        params = request.arguments.values().map(it.str()).clone()
    }

    if request.body != '' {
        params << request.body
    }

    if request.parameters.len != 0 {
        mut param_map := map[string]Any{} // Store parameters with correct types

        for param_name, param_value in request.parameters {
            operation_param := request.operation.parameters.filter(it.name == param_name)
            if operation_param.len > 0 {
                param_schema := operation_param[0].schema as Schema
                param_type := param_schema.typ
                param_format := param_schema.format

                // Convert parameter value to corresponding type
                match param_type {
                    'integer' {
                        match param_format {
                            'int32' {
                                param_map[param_name] = param_value.int() // Convert to int
                            }
                            'int64' {
                                param_map[param_name] = param_value.i64() // Convert to i64
                            }
                            else {
                                param_map[param_name] = param_value.int() // Default to int
                            }
                        }
                    }
                    'string' {
                        param_map[param_name] = param_value // Already a string
                    }
                    'boolean' {
                        param_map[param_name] = param_value.bool() // Convert to bool
                    }
                    'number' {
                        match param_format {
                            'float' {
                                param_map[param_name] = param_value.f32() // Convert to float
                            }
                            'double' {
                                param_map[param_name] = param_value.f64() // Convert to double
                            }
                            else {
                                param_map[param_name] = param_value.f64() // Default to double
                            }
                        }
                    }
                    else {
                        param_map[param_name] = param_value // Leave as string for unknown types
                    }
                }
            } else {
                // If the parameter is not defined in the OpenAPI operation, skip or log it
                println('Unknown parameter: $param_name')
            }
        }

        // Encode the parameter map to JSON if needed
        params << json.encode(param_map.str())
    }

    call := ProcedureCall{
        method: request.operation.operation_id
        params: "[${params.join(',')}]" // Keep as a string since ProcedureCall expects a string
    }

    // Process the procedure call
    procedure_response := handler.processor.process(
        call,
        ProcessParams{
            timeout: 30 // Set timeout in seconds
        }
    ) or {
        // Handle ProcedureError
        if err is processor.ProcedureError {
            return Response{
                status: http.status_from_int(err.code()) // Map ProcedureError reason to HTTP status code
                body: json.encode({
                    'error': err.msg()
                })
            }
        }
        return error('Unexpected error: $err')
    }

    // Convert returned procedure response to OpenAPI response
    return Response{
        status: http.Status.ok // Assuming success if no error
        body: procedure_response.result
    }
}