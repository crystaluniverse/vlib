module code

// import freeflowuniverse.crystallib.core.pathlib {Path}
// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.core.codeparser
import freeflowuniverse.crystallib.core.codemodel {Module, CodeFile, Function, Struct}

// read reads an actor from a given v module
pub fn (actor Actor) write(actor_path string) ! {
	mod := actor.to_module()!
	mod.write_v(actor_path)!
}

pub fn (actor Actor) to_module () !Module {
	mut mod := Module {
		name: actor.name
	}

	mut files := []CodeFile{}
	for object in actor.objects {
		files << object.to_code_file()!
	}

	
	// for object in actor.objects.map(it.structure.name) {
	// 	default_methods
	// 	object_methods := actor.methods.filter(it.name.starts_with('${actor.name}_${object}'))
	// 	files << object
	// }
	
	// for method in actor.methods {
	// 	files << object.to_code_file()!
	// }

	// for file in mod.files {
	// 	if file.name.starts_with('model_') {
	// 		actor.objects << file_to_base_object(file)!
	// 	}

	// 	if file.name.starts_with('${actor_name}_') {
	// 		actor.methods << file_to_actor_methods(file)!
	// 	}
	// }

	return mod
}

fn (object BaseObject) to_code_file() !CodeFile {
	// object_name := texttools.name_fix_snake_to_pascal(file.name.all_after('model_').all_before('.'))
	// object_structure := file.structs().filter(it.name == object_name)[0]
	return CodeFile {
		name: 'model_${object.structure.name}'
		items: [object.structure]
	}
}

// fn file_to_actor_methods(file CodeFile) ![]ActorMethod {
// 	return file.functions().map(ActorMethod{name: it.name, func: it})
// }