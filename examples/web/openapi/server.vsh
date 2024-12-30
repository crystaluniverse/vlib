#!/usr/bin/env -S v -w -n -enable-globals run

import os
import veb
import json
import freeflowuniverse.crystallib.web.openapi {Server, Context, Handler, Request, Response}

const spec_path = '${os.dir(@FILE)}/data/openapi.json'
const spec_json = os.read_file(spec_path) or {panic(err)}

// Main function to start the server
fn main() {
    // Create the OpenAPI specification (mocked for now)

    // Initialize the server
    mut server := &Server{
        specification: openapi.json_decode(spec_json)!
        handler: ExampleHandler{}
    }

    // Start the veb web server
    veb.run[Server, Context](mut server, 8081)
}

pub struct ExampleHandler{}

fn (handler ExampleHandler) handle(request Request) !Response {
    return Response {
		status: .ok
		body: '${request}'
	}
}