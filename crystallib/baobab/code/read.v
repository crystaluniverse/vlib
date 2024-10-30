module code

import freeflowuniverse.crystallib.core.pathlib {Path}
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.codemodel {Module, CodeFile, Function, Struct}

// read reads an actor from a given v module
pub fn read(actor_path string) !Actor {
	mod := codeparser.parse_module(actor_path)!
	return module_to_actor(mod)!
}

pub fn module_to_actor(mod Module) !Actor {
	mut actor := Actor {
		name: mod.name
	}

	for file in mod.files {
		if file.name.starts_with('model_') {
			actor.objects << file_to_base_object(file)!
		}

		if file.name.starts_with('${actor.name}_') {
			actor.methods << file_to_actor_methods(file)!
		}
	}

	return actor
}

fn file_to_base_object(file CodeFile) !BaseObject {
	object_name := texttools.name_fix_snake_to_pascal(file.name.all_after('model_').all_before('.'))
	object_structure := file.structs().filter(it.name == object_name)[0]
	return BaseObject {
		structure: object_structure
	}
}

fn file_to_actor_methods(file CodeFile) ![]ActorMethod {
	return file.functions().map(ActorMethod{name: it.name, func: it})
}