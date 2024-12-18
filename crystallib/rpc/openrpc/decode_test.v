module openrpc

import json
import x.json2
import os
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.jsonschema

const doc_path = '${os.dir(@FILE)}/testdata/openrpc.json'

fn test_decode() ! {
	mut doc_file := pathlib.get_file(path: doc_path)!
	content := doc_file.read()!
	object := decode(content)!

	assert object.openrpc == '1.0.0-rc1'
	assert object.methods.map(it.name) == ['list_pets', 'create_pet', 'get_pet']
}
