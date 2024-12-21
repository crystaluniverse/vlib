module generator

import freeflowuniverse.crystallib.core.codemodel { Folder, IFile, VFile, CodeItem, File, Function, Import, Module, Struct, CustomCode }
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.hero.baobab.specification {ActorMethod, ActorSpecification}

pub fn generate_command_file(spec ActorSpecification) !VFile {
	mut items := []CodeItem{}
	items << CustomCode{generate_cmd_function(spec)}
	for i in spec.methods {
		items << CustomCode{generate_method_cmd_function(spec.name, i)}
	}
	return VFile {
		name: 'command'
		items: items
	}
}
	
pub fn generate_cmd_function(spec ActorSpecification) string {
	actor_name_snake := texttools.name_fix_snake(spec.name)
	mut cmd_function := "
	pub fn cmd() Command {
		mut cmd := Command{
			name: '${actor_name_snake}'
			usage: ''
			description: '${spec.description}'
			execute: cmd_execute
		}
	"
	
	mut method_cmds := []string{}
	for method in spec.methods {
		method_cmds << generate_method_cmd(method)
	}

	cmd_function += method_cmds.join_lines()

	return cmd_function
}

pub fn generate_method_cmd(method ActorMethod) string {
	method_name_snake := texttools.name_fix_snake(method.name)
	return "		
		mut cmd_${method_name_snake} := Command{
			sort_flags: true
			name: '${method_name_snake}'
			execute: cmd_${method_name_snake}_execute
			description: '${method.description}'
		}
	"
}

pub fn generate_method_cmd_function(actor_name string, method ActorMethod) string {
	mut operation_handlers := []string{}
	mut routes := []string{}

	actor_name_snake := texttools.name_fix_snake(actor_name)
	return '
		fn cmd_${method.name}(cmd Command) ! {
			result := ${actor_name_snake}.${method.name}()!
			console.print_stdout(result.str())
		}
	'
}