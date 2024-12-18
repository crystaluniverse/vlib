module installer

import os
import freeflowuniverse.crystallib.core.pathlib
import json
import freeflowuniverse.crystallib.ui
import freeflowuniverse.crystallib.ui.console
// import freeflowuniverse.crystallib.core.texttools
// import freeflowuniverse.crystallib.core.generator.generic

@[params]
pub struct GeneratorArgs {
pub mut:
	name                  string
	title                 string
	build_deps            []string
	install_deps          []string
	supported_platforms   []string
	clients               []string
	configure_interactive bool
	reset                 bool // regenerate all, dangerous !!!
	interactive           bool = true
	path                  string
	isserver              bool
}

pub struct TemplateItem {
pub mut:
	// dest string // directory where the template needs to go too
	name string // name which can be used for variable
	path string // where template is in the template dir
}

pub fn do(args_ GeneratorArgs) ! {
	mut args := args_

	if args.path.len == 0 {
		args.path = os.getwd()
	}

	config_path := '${args.path}/generate_config.json'

	if os.exists(config_path) && args.reset {
		os.rm(config_path)!
	}

	if os.exists(config_path) {
		mut p_config := pathlib.get_file(path: config_path)!
		config := p_config.read()!
		args = json.decode(GeneratorArgs, config)!
	} else {
		// now ask the questions if interactive
		mut myui := ui.new()!

		if args.interactive {
			console.clear()
			ok := myui.ask_yesno(
				question: "are you sure you want to generate in dir:'${args.path}'?"
			)!
			if !ok {
				return error("can't continue, user aborted.")
			}
		}

		name := args.path.trim_right('/').split('/').last() // get name of current dir

		if args.name.len == 0 {
			if args.interactive {
				args.name = myui.ask_question(
					question: '\nwhat is the name of your module?'
					default:  name
				)!
			} else {
				args.name = name
			}
		}
		if args.title.len == 0 {
			if args.interactive {
				args.title = myui.ask_question(
					question: 'what is the tile of your installer, if empy same as name?'
					default:  args.name
				)!
			} else {
				args.title = args.name
			}
		}
		if args.interactive {
			args.isserver = myui.ask_yesno(question: 'Are you generating for a server app?')!
		}
		if args.build_deps.len == 0 {
			if args.interactive {
				args.build_deps = myui.ask_dropdown_multiple(
					question: 'Which build deps do you want?'
					items:    [
						'none',
						'docker',
						'golang',
						'python',
						'nodejs',
						'rust',
					]
				)!
			} else {
				return error('please specify build_deps')
			}
		}
		if args.install_deps.len == 0 {
			if args.interactive {
				args.install_deps = myui.ask_dropdown_multiple(
					question: 'Which install deps do you want?'
					items:    [
						'none',
						'docker',
						'golang',
						'python',
						'nodejs',
						'rust',
					]
				)!
			} else {
				return error('please specify install_deps')
			}
		}

		if args.supported_platforms.len == 0 {
			if args.interactive {
				args.supported_platforms = myui.ask_dropdown_multiple(
					question: 'Which platforms do you support?'
					items:    ['ubuntu', 'osx', 'arch']
				)!
			} else {
				return error('please specify supported_platforms')
			}
		}

		// call the generic ones
		mut args_generic := generic.GeneratorArgs
		{
			name:                  args.name
			configure_interactive: args.configure_interactive
			reset:                 args.reset
			interactive:           args.interactive
			path:                  args.path
			clients:               args.clients
		}

		generic.clients_ask(args_generic)!
		generic.generate(args_generic)!

		mut p_config := pathlib.get_file(path: config_path, create: true)!
		args.reset = false
		data := json.encode(args)
		deps_check(args)!
		platform_check(args)!
		console.print_debug('\n## Your arguments, will be saved for next time.')
		console.print_debug(args)

		p_config.write(data)!
	}
	generate(args)!
}

pub fn generate(args_ GeneratorArgs) ! {
	mut args := args_
	mut a := $tmpl('templates/builder.vtemplate')
	pathlib.template_write(a, '${args.path}/builder.v', args.reset)!

	// mut b := $tmpl('templates/configure.vtemplate')
	// pathlib.template_write(b, '${args.path}/configure.v', args.reset)!

	mut c := $tmpl('templates/installer.vtemplate')
	pathlib.template_write(c, '${args.path}/installer.v', args.reset)!

	if args.isserver {
		mut d := $tmpl('templates/server.vtemplate')
		pathlib.template_write(d, '${args.path}/server.v', args.reset)!
	}

	mut e := $tmpl('templates/readme.md')
	pathlib.template_write(e, '${args.path}/readme.md', args.reset)!
}

fn deps_check(args GeneratorArgs) ! {
	ok := 'rust,golang,php,nodejs,python,none,docker'
	ok2 := ok.split(',')
	for i in args.build_deps {
		if i !in ok2 {
			return error('cannot find ${i} in choices for build deps. Valid ones are ${ok}')
		}
	}
	for i in args.install_deps {
		if i !in ok2 {
			return error('cannot find ${i} in choices for install deps. Valid ones are ${ok}')
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
