module generic

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib

fn generate_exec(path string, reset bool) ! {
	mut args := args_get(path)!
	console.print_debug('generate code for path: ${path}')

	if reset {
		args.reset = true
	}

	mut path_actions := pathlib.get(args.path + '/${args.name}_actions.v')
	if args.reset {
		path_actions.delete()!
	}
	if !path_actions.exists() && args.cat == .installer {
		console.print_debug('write installer actions')
		mut templ_1 := $tmpl('templates/objname_actions.vtemplate')
		pathlib.template_write(templ_1, '${args.path}/${args.name}_actions.v', true)!
	}

	mut templ_2 := $tmpl('templates/objname_factory_.vtemplate')

	pathlib.template_write(templ_2, '${args.path}/${args.name}_factory_.v', true)!

	mut path_model := pathlib.get(args.path + '/${args.name}_model.v')
	if args.reset || !path_model.exists() {
		console.print_debug('write model.')
		mut templ_3 := $tmpl('templates/objname_model.vtemplate')
		pathlib.template_write(templ_3, '${args.path}/${args.name}_model.v', true)!
	}

	// TODO: check case sensistivity for delete
	mut path_readme := pathlib.get(args.path + '/readme.md')
	if args.reset || !path_readme.exists() {
		mut templ_readme := $tmpl('templates/readme.md')
		pathlib.template_write(templ_readme, '${args.path}/readme.md', true)!
	}

	mut path_templ_dir := pathlib.get_dir(path: args.path + '/templates', create: false)!
	if args.reset {
		path_templ_dir.delete()!
	}
	if args.templates {
		if !path_templ_dir.exists() {
			mut templ_6 := $tmpl('templates/atemplate.yaml')
			pathlib.template_write(templ_6, '${args.path}/templates/atemplate.yaml', true)!
		}
	}
}

fn platform_check(args GeneratorArgs) ! {
	ok := 'osx,ubuntu,arch'
	ok2 := ok.split(',')
	for i in args.supported_platforms {
		if i !in ok2 {
			return error('cannot find ${i} in choices for supported_platforms. Valid ones are ${ok}')
		}
	}
}

pub fn (args GeneratorArgs) platform_check_str() string {
	mut out := ''

	if 'osx' in args.supported_platforms {
		out += 'myplatform == .osx || '
	}
	if 'ubuntu' in args.supported_platforms {
		out += 'myplatform == .ubuntu ||'
	}
	if 'arch' in args.supported_platforms {
		out += 'myplatform == .arch ||'
	}
	out = out.trim_right('|')
	return out
}
