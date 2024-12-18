module jsonschema

import json
import x.json2
import os
import freeflowuniverse.crystallib.core.pathlib

const testdata = '${os.dir(@FILE)}/testdata'

struct Pet {
	name string
}

fn test_decode() ! {
	mut pet_schema_file := pathlib.get_file(
		path: '${testdata}/pet.json'
	)!
	pet_schema_str := pet_schema_file.read()!
	pet_schema := decode(pet_schema_str)!
	assert pet_schema == Schema{
		typ:        'object'
		properties: {
			'name': Schema{
				typ: 'string'
			}
		}
		required:   ['name']
	}
}

fn test_decode_schemaref() ! {
	mut pet_schema_file := pathlib.get_file(
		path: '${testdata}/pet.json'
	)!
	pet_schema_str := pet_schema_file.read()!
	pet_schemaref := decode(pet_schema_str)!
	assert pet_schemaref == Schema{
		typ:        'object'
		properties: {
			'name': Schema{
				typ: 'string'
			}
		}
		required:   ['name']
	}
}
