module code

import freeflowuniverse.crystallib.core.pathlib {Path}
import freeflowuniverse.crystallib.core.codeparser
import os

const actor_name = 'testactor'
const actor_path = '${os.dir(@FILE)}/testdata/${actor_name}'

pub fn test_parse_actor_methods() ! {
	actor_methods_file := codeparser.parse_file('${actor_path}/${actor_name}_base_object.v')!
	actor_methods := file_to_actor_methods(actor_methods_file)!
	assert actor_methods.len == 6
	assert actor_methods.map(it.name) == [
		'new_base_object',
		'get_base_object',
		'set_base_object',
		'delete_base_object',
		'list_base_object',
		'filter_base_object'
	]
}

pub fn test_parse_base_object() ! {
	base_object_file := codeparser.parse_file('${actor_path}/model_base_object.v')!
	base_object := file_to_base_object(base_object_file)!
	assert base_object.structure.name == 'BaseObject'
	assert base_object.structure.fields.map(it.name) == ['text', 'number']
}

pub fn test_module_to_actor() ! {
	mod := codeparser.parse_module(actor_path)!
	actor := module_to_actor(mod)!
	assert actor.methods.len == 13
	assert actor.objects.len == 2
}

pub fn test_read() ! {
	actor := read(actor_path)!
	assert actor.methods.len == 13
	assert actor.objects.len == 2
}