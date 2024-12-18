module generic

import freeflowuniverse.crystallib.ui.console
import os
import freeflowuniverse.crystallib.core.pathlib

// will ask questions when not in force mode
// & generate the module
pub fn generate(args_ GeneratorArgs) ! {
	mut myconsole := console.new()
	mut args := args_

	console.print_header('Generate code for path: ${args.path} (reset:${args.force}, force:${args.force})')
	console.print_debug(args)
	if args.path == '' {
		args.path = os.getwd()
	}

	if args.name == '' {
		args.name = os.base(args.path)
	}

	if args.force {
		mut config_path0 := pathlib.get_file(path: '${args.path}/.heroscript', create: false)!
		if !config_path0.exists() {
			return error("can't generate in force mode (non interactive) if ${config_path0.path} not found.")
		}
		generate_exec(args.path, args.reset)!
		return
	}

	console.clear()
	console.print_header('Configure generation of code for a module on path:')
	console.print_green('Path: ${args.path}')
	console.lf()

	mut config_path := pathlib.get_file(path: '${args.path}/.heroscript', create: false)!
	mut pathok := false
	if config_path.exists() {
		console.print_stdout(config_path.read()!)
		console.lf()
		myyes := myconsole.ask_yesno(
			description: 'We found this heroscript, do you want to make a new one?'
		)!
		if myyes {
			config_path.delete()!
			pathok = true
		} else {
			myyes2 := myconsole.ask_yesno(description: 'Do you want to run it?')!
			if myyes2 {
				generate_exec(args.path, args.reset)!
			} else {
				console.print_stderr('Generation aborted.')
			}
			return
		}
	}

	if pathok == false {
		yesno := myconsole.ask_yesno(description: 'Is this path ok?')!
		if !yesno {
			return error("can't continue without a valid path")
		}
	}

	mycat := myconsole.ask_dropdown(
		description: 'Category of the generator'
		question:    'What is the category of the generator?'
		items:       [
			'installer',
			'client',
		]
		warning:     'Please select a category'
	)!

	if mycat == 'installer' {
		args.cat = .installer
	} else {
		args.cat = .client
	}

	// if args.name==""{
	// 	yesno := myconsole.ask_yesno(description: 'Are you happy with name ${args.name}?')!
	// 	if !yesno {
	// 		return error("can't continue without a valid name, rename the directory you operate in.")
	// 	}
	// }

	args.classname = myconsole.ask_question(
		description: 'Class name of the ${mycat}'
		question:    'What is the class name of the generator e.g. MyClass ?'
		warning:     'Please provide a valid class name for the generator'
		minlen:      4
	)!

	args.title = myconsole.ask_question(
		description: 'Title of the ${mycat} (optional)'
	)!

	if args.cat == .installer {
		args.hasconfig = myconsole.ask_yesno(
			description: 'Does your installer have a config (normally yes)?'
		)!
	}

	if args.hasconfig {
		args.default = myconsole.ask_yesno(
			description: 'Is it ok when doing new() that a default is created (normally yes)?'
		)!
		args.singleton = !myconsole.ask_yesno(
			description: 'Can there be multiple instances (normally yes)?'
		)!
	}

	// args.supported_platforms = myconsole.ask_dropdown_multiple(
	// 	description: 'Supported platforms'
	// 	question:    'Which platforms are supported?'
	// 	items:       [
	// 		'osx',
	// 		'ubuntu',
	// 		'arch',
	// 	]
	// 	warning: 'Please select one or more platforms'
	// )!

	if args.cat == .installer {
		args.templates = myconsole.ask_yesno(
			description: 'Will there be templates available for your installer?'
		)!

		args.startupmanager = myconsole.ask_yesno(
			description: 'Is this an installer which will be managed by a startup mananger?'
		)!

		args.build = myconsole.ask_yesno(
			description: 'Are there builders for the installers (compilation)'
		)!
	}

	// args.reset = myconsole.ask_yesno(
	// 	description: 'Reset, overwrite code.'
	// 	question:    'This will overwrite all files in your existing dir, be carefule?'
	// )!
	create_heroscript(args)!
	generate_exec(args.path, true)!
}

pub fn create_heroscript(args GeneratorArgs) ! {
	mut script := ''
	if args.cat == .installer {
		script = "
!!hero_code.generate_installer
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${if args.singleton {
			'1'
		} else {
			'0'
		}}
    templates:${if args.templates { '1' } else { '0' }}
    default:${if args.default {
			'1'
		} else {
			'0'
		}}
    title:'${args.title}'
    supported_platforms:''
    reset:${if args.reset {
			'1'
		} else {
			'0'
		}}
    startupmanager:${if args.startupmanager { '1' } else { '0' }}
	hasconfig:${if args.hasconfig {
			'1'
		} else {
			'0'
		}}
    build:${if args.build {
			'1'
		} else {
			'0'
		}}"
	} else {
		script = "
!!hero_code.generate_client
    name:'${args.name}'
    classname:'${args.classname}'
    singleton:${if args.singleton {
			'1'
		} else {
			'0'
		}}
    default:${if args.default { '1' } else { '0' }}
	hasconfig:${if args.hasconfig {
			'1'
		} else {
			'0'
		}}
    reset:${if args.reset {
			'1'
		} else {
			'0'
		}}"
	}
	if !os.exists(args.path) {
		os.mkdir(args.path)!
	}
	os.write_file('${args.path}/.heroscript', script)!
}
