module osal

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
// import freeflowuniverse.crystallib.ui.console

// will return temporary path which then can be executed, is a helper function for making script out of command
pub fn cmd_to_script_path(cmd Command) !string {
	// all will be done over filessytem now
	mut cmdcontent := texttools.dedent(cmd.cmd)
	if !cmdcontent.ends_with('\n') {
		cmdcontent += '\n'
	}

	if cmd.environment.len > 0 {
		mut cmdenv := ''
		for key, val in cmd.environment {
			cmdenv += "export ${key}='${val}'\n"
		}
		cmdcontent = cmdenv + '\n' + cmdcontent
		// process.set_environment(args.environment)
	}

	// use bash debug and die on error features
	mut firstlines := ''
	mut extension := 'sh'
	if cmd.runtime == .bash || cmd.runtime == .herocmd {
		if !cmd.cmd.contains('#!/bin/bash') {
			firstlines = '#!/bin/bash\n\n'
			if !cmd.ignore_error {
				firstlines += 'set -e\n' // exec 2>&1\n
			} else {
				firstlines += 'set +e\n' // exec 2>&1\n
			}
			if cmd.debug {
				firstlines += 'set -x\n' // exec 2>&1\n
			}
		}
		if !cmd.interactive {
			// firstlines += 'export DEBIAN_FRONTEND=noninteractive TERM=xterm\n\n'
			firstlines += 'export DEBIAN_FRONTEND=noninteractive\n\n'
		}
		if cmd.work_folder.len > 0 {
			firstlines += 'cd ${cmd.work_folder}\n'
		}
		if cmd.runtime == .herocmd {
			firstlines += 'hero ' // put hero on the next line, the cmdcontent will be appended then
			extension = 'hero'
		}
	} else if cmd.runtime == .python {
		firstlines = '#!/usr/bin/env python3\n\n'
		extension = 'py'
	} else if cmd.runtime == .heroscript {
		firstlines = '#!/usr/bin/env hero\n\n'
		extension = 'hero'
	} else if cmd.runtime == .v {
		firstlines = '#!/usr/bin/env v\n\n'
		extension = 'vsh'
	} else {
		panic("can't find runtime type")
	}

	cmdcontent = firstlines + cmdcontent

	mut scriptpath := if cmd.scriptpath.len > 0 {
		cmd.scriptpath
	} else {
		''
	}
	scriptpath = pathlib.temp_write(
		text: cmdcontent
		path: scriptpath
		name: cmd.name
		ext:  extension
	) or { return error('error: cannot write script to execute: ${err}') }
	// console.print_debug(" - scriptpath: ${cmd.scriptpath}")
	return scriptpath
}
