module openrpc

import os
import json
import freeflowuniverse.crystallib.core.codemodel { Alias, Struct }
import freeflowuniverse.crystallib.core.pathlib

const doc_path = '${os.dir(@FILE)}/testdata/openrpc.json'

fn test_generate_model() ! {
	mut doc_file := pathlib.get_file(path: doc_path)!
	content := doc_file.read()!
	object := decode(content)!
	model := object.generate_model()!

	assert model.len == 3
	assert model[0] is Alias
	pet_id := model[0] as Alias
	assert pet_id.name == 'PetId'
	assert pet_id.typ.symbol == 'int'

	assert model[1] is Struct
	pet_struct := model[1] as Struct
	assert pet_struct.name == 'Pet'
	assert pet_struct.fields.len == 3

	// test field is `id PetId @[required]`
	assert pet_struct.fields[0].name == 'id'
	assert pet_struct.fields[0].typ.symbol == 'PetId'
	assert pet_struct.fields[0].attrs.len == 1
	assert pet_struct.fields[0].attrs[0].name == 'required'

	// test field is `name string @[required]`
	assert pet_struct.fields[1].name == 'name'
	assert pet_struct.fields[1].typ.symbol == 'string'
	assert pet_struct.fields[1].attrs.len == 1
	assert pet_struct.fields[1].attrs[0].name == 'required'

	// test field is `tag string`
	assert pet_struct.fields[2].name == 'tag'
	assert pet_struct.fields[2].typ.symbol == 'string'
	assert pet_struct.fields[2].attrs.len == 0

	assert model[2] is Alias
	pets_alias := model[2] as Alias
	assert pets_alias.name == 'Pets'
	assert pets_alias.typ.symbol == '[]Pet'
}
