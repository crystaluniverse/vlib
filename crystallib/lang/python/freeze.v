module python

// // remember the requirements list for all pips
// pub fn (mut py PythonEnv) freeze(name string) ! {
// 	console.print_debug('Freezing requirements for environment: ${py.name}')
// 	cmd := '
// 	cd ${py.path.path}
// 	source bin/activate
// 	python3 -m pip freeze
// 	'
// 	res := os.execute(cmd)
// 	if res.exit_code > 0 {
// 		console.print_stderr('Failed to freeze requirements: ${res}')
// 		return error('could not execute freeze.\n${res}\n${cmd}')
// 	}
// 	console.print_debug('Successfully froze requirements')
// }

// remember the requirements list for all pips
// pub fn (mut py PythonEnv) unfreeze(name string) ! {
// 	// requirements := py.db.get('freeze_${name}')!
// 	mut p := py.path.file_get_new('requirements.txt')!
// 	p.write(requirements)!
// 	cmd := '
// 	cd ${py.path.path}
// 	source bin/activate
// 	python3 -m pip install -r requirements.txt
// 	'
// 	res := os.execute(cmd)
// 	if res.exit_code > 0 {
// 		return error('could not execute unfreeze.\n${res}\n${cmd}')
// 	}
// }
