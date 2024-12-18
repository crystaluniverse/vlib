module python

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.installers.lang.python
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.ui.console
import os

pub struct PythonEnv {
pub mut:
	name string
	path pathlib.Path
	db   dbfs.DB
}

@[params]
pub struct PythonEnvArgs {
pub mut:
	name  string = 'default'
	reset bool
}

pub fn new(args_ PythonEnvArgs) !PythonEnv {
	console.print_debug('Creating new Python environment with name: ${args_.name}')
	mut args := args_
	name := texttools.name_fix(args.name)

	pp := '${os.home_dir()}/hero/python/${name}'
	console.print_debug('Python environment path: ${pp}')

	mut c := base.context()!
	mut py := PythonEnv{
		name: name
		path: pathlib.get_dir(path: pp, create: true)!
		db:   c.db_get('python_${args.name}')!
	}

	key_install := 'pips_${py.name}_install'
	key_update := 'pips_${py.name}_update'
	if !os.exists('${pp}/bin/activate') {
		console.print_debug('Python environment directory does not exist, triggering reset')
		args.reset = true
	}
	if args.reset {
		console.print_debug('Resetting Python environment')
		py.pips_done_reset()!
		py.db.delete(key: key_install)!
		py.db.delete(key: key_update)!
	}

	toinstall := !py.db.exists(key: key_install)!
	if toinstall {
		console.print_debug('Installing Python environment')
		python.install()!
		py.init_env()!
		py.db.set(key: key_install, value: 'done')!
		console.print_debug('Python environment setup complete')
	}

	toupdate := !py.db.exists(key: key_update)!
	if toupdate {
		console.print_debug('Updating Python environment')
		py.update()!
		py.db.set(key: key_update, value: 'done')!
		console.print_debug('Python environment update complete')
	}

	return py
}

// comma separated list of packages to install
pub fn (py PythonEnv) init_env() ! {
	console.print_green('Initializing Python virtual environment at: ${py.path.path}')
	cmd := '
	cd ${py.path.path}
	python3 -m venv .
	'
	osal.exec(cmd: cmd)!
	console.print_debug('Virtual environment initialization complete')
}

// comma separated list of packages to install
pub fn (py PythonEnv) update() ! {
	console.print_green('Updating pip in Python environment: ${py.name}')
	cmd := '
	cd ${py.path.path}	
	source bin/activate
	python3 -m pip install --upgrade pip
	'
	osal.exec(cmd: cmd)!
	console.print_debug('Pip update complete')
}

// comma separated list of packages to install
pub fn (mut py PythonEnv) pip(packages string) ! {
	mut to_install := []string{}
	for i in packages.split(',') {
		pip := i.trim_space()
		if !py.pips_done_check(pip)! {
			to_install << pip
			console.print_debug('Package to install: ${pip}')
		}
	}
	if to_install.len == 0 {
		return
	}
	console.print_debug('Installing Python packages: ${packages}')
	packages2 := to_install.join(' ')
	cmd := '
	cd ${py.path.path}
	source bin/activate
	pip3 install ${packages2} -q
	'
	osal.exec(cmd: cmd)!
	// After successful installation, record the packages as done
	for pip in to_install {
		py.pips_done_add(pip)!
		console.print_debug('Successfully installed package: ${pip}')
	}
}

pub fn (mut py PythonEnv) pips_done_reset() ! {
	console.print_debug('Resetting installed packages list for environment: ${py.name}')
	py.db.delete(key: 'pips_${py.name}')!
}

pub fn (mut py PythonEnv) pips_done() ![]string {
	// console.print_debug('Getting list of installed packages for environment: ${py.name}')
	mut res := []string{}
	pips := py.db.get(key: 'pips_${py.name}') or { '' }
	for pip_ in pips.split_into_lines() {
		pip := pip_.trim_space()
		if pip !in res && pip.len > 0 {
			res << pip
		}
	}
	// console.print_debug('Found ${res.len} installed packages')
	return res
}

pub fn (mut py PythonEnv) pips_done_add(name string) ! {
	console.print_debug('Adding package ${name} to installed packages list')
	mut pips := py.pips_done()!
	if name in pips {
		// console.print_debug('Package ${name} already marked as installed')
		return
	}
	pips << name
	out := pips.join_lines()
	py.db.set(key: 'pips_${py.name}', value: out)!
	console.print_debug('Successfully added package ${name} to installed list')
}

pub fn (mut py PythonEnv) pips_done_check(name string) !bool {
	// console.print_debug('Checking if package ${name} is installed')
	mut pips := py.pips_done()!
	return name in pips
}
