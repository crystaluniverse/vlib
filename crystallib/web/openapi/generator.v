module openapi

import json
import os
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib

pub fn generate() ! {
	testdata_path := os.dir(@FILE) + '/templates/petstor.json'
	// testdata_path := os.dir(@FILE) + '/templates/qdrant.json'

	mut example_data := pathlib.get_file(path: testdata_path)!
	json_str := example_data.read()!

	// Decoding the JSON string into the Openapi struct
	mut api_data := json.decode(OpenAPI, json_str) or {
		console.print_debug('Failed to decode JSON: ${err}')
		return
	}

	// Example usage of the decoded data
	console.print_debug('OpenAPI version: ${api_data.openapi}')
	console.print_debug('API title: ${api_data.info.title}')

	// Encoding the Openapi struct back into JSON
	encoded_json := json.encode(api_data)
	console.print_debug('Encoded JSON: ${encoded_json}')

	// now the code to generate the rest client needs to follow
}
