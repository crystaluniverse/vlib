module python

import freeflowuniverse.crystallib.osal
// import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import os
import freeflowuniverse.crystallib.ui.console

@[params]
pub struct PythonExecArgs {
pub mut:
	cmd                string @[required]
	result_delimiter   string = '==RESULT=='
	ok_delimiter       string = '==OK=='
	python_script_name string // if used will put it in root of the sandbox under that name
	stdout             bool
}

pub fn (py PythonEnv) exec(args PythonExecArgs) !string {
	mut cmd := texttools.dedent(args.cmd)
	mut debug := false
	if cmd.contains('DEBUG()') {
		cmd = cmd.replace('DEBUG()', 'from IPython import embed; embed()')
		debug = true
	}

	cmd += "\n\nprint(\"${args.ok_delimiter}\")\n"

	mut scriptpath := ''
	if args.python_script_name.len > 0 {
		scriptpath = '${py.path.path}/${args.python_script_name}.py'
		mut p := pathlib.get_file(path: scriptpath, create: true)!
		p.write(cmd)!
	} else {
		scriptpath = pathlib.temp_write(text: cmd, ext: 'py') or {
			return error('error: cannot write script to execute: ${err}')
		}
	}
	// console.print_debug(" - scriptpath: ${scriptpath}")
	os.chmod(scriptpath, 0o777)!

	cmd2 := '
	cd ${py.path.path}
	source bin/activate
	python3 ${scriptpath}
	'
	if args.stdout || debug {
		console.print_debug(cmd2)
	}
	mut job := osal.Job{}
	if debug {
		osal.execute_interactive(cmd2)!
	} else {
		job = osal.exec(cmd: cmd2, stdout: args.stdout, raise_error: false)!
	}

	if job.exit_code > 0 {
		// means error
		mut msg := ' - error in execution of python script: ${scriptpath}\n'
		msg += 'ERROR:\n'
		msg += job.error.str()
		return error(msg)
	}

	// console.print_debug(job)

	mut o := []string{}
	mut start := false
	for l in job.output.split_into_lines() {
		if l.trim_space().starts_with(args.result_delimiter) {
			start = true
			continue
		}
		if l.trim_space().starts_with(args.ok_delimiter) {
			break
		}
		if start {
			o << l
		}
	}

	return o.join_lines()
}
