module main

import os
import json
import freeflowuniverse.crystallib.data.openapi

const spec_path = '${os.dir(@FILE)}/openapi.json'

pub fn main() {
	do() or { panic(err) }
}

pub fn do() ! {
	spec_json := os.read_file(spec_path)!
	spec := json.decode(openapi.OpenAPI, spec_json)!
	println(spec.components)
}
