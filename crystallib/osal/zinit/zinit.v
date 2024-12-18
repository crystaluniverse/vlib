module zinit

import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.data.ourtime
import os
import json

@[heap]
pub struct Zinit {
pub mut:
	processes map[string]ZProcess
	path      pathlib.Path
	pathcmds  pathlib.Path
}

// will delete the process if it exists while starting
pub fn (mut zinit Zinit) new(args_ ZProcessNewArgs) !ZProcess {
	console.print_header(' zinit process new')
	mut args := args_

	if args.cmd.len == 0 {
		$if debug {
			print_backtrace()
		}
		return error('cmd cannot be empty for ${args} in zinit.')
	}

	if zinit.exists(args.name) {
		mut p := zinit.get(args.name)!
		p.destroy()!
	}

	mut zp := ZProcess{
		name:     args.name
		cmd:      args.cmd
		cmd_test: args.cmd_test
		cmd_stop: args.cmd_stop
		env:      args.env.move()
		after:    args.after
		start:    args.start
		restart:  args.restart
		oneshot:  args.oneshot
		workdir:  args.workdir
	}

	zinit.cmd_write(args.name, args.cmd, '_start', {}, args.workdir)!
	zinit.cmd_write(args.name, args.cmd_test, '_test', {}, args.workdir)!
	zinit.cmd_write(args.name, args.cmd_stop, '_stop', {}, args.workdir)!

	mut json_path := zinit.pathcmds.file_get_new('${args.name}.json')!
	json_content := json.encode(args)
	json_path.write(json_content)!

	mut pathyaml := zinit.path.file_get_new(zp.name + '.yaml')!
	// console.print_debug('debug zprocess path yaml: ${pathyaml}')
	pathyaml.write(zp.config_content()!)!
	if zp.start {
		zp.start()!
	}
	zinit.processes[args.name] = zp

	return zp
}

fn (mut zinit Zinit) cmd_write(name string, cmd string, cat string, env map[string]string, workdir string) !string {
	if cmd.trim_space() == '' {
		return ''
	}
	mut zinitobj := new()!
	mut pathcmd := zinitobj.pathcmds.file_get_new('${name}${cat}.sh')!
	mut cmd_out := '#!/bin/bash\nset -e\n\n'

	if cat == '_start' {
		cmd_out += 'echo === START ======== ${ourtime.now().str()} === \n'
	}
	for key, val in env {
		cmd_out += '${key}=${val}\n'
	}

	if workdir.trim_space() != '' {
		cmd_out += 'cd ${workdir.trim_space()}\n'
	}

	cmd_out += texttools.dedent(cmd) + '\n'
	pathcmd.write(cmd_out)!
	pathcmd.chmod(0x770)!
	return '/bin/bash -c ${pathcmd.path}'
}

pub fn (mut zinit Zinit) get(name_ string) !ZProcess {
	name := texttools.name_fix(name_)
	// console.print_debug(zinit)
	return zinit.processes[name] or { return error("cannot find process in zinit:'${name}'") }
}

pub fn (mut zinit Zinit) exists(name_ string) bool {
	name := texttools.name_fix(name_)
	if name in zinit.processes {
		return true
	}
	return false
}

pub fn (mut zinit Zinit) stop(name string) ! {
	mut p := zinit.get(name)!

	p.stop()!
}

pub fn (mut zinit Zinit) start(name string) ! {
	mut p := zinit.get(name)!
	p.start()!
}

pub fn (mut zinit Zinit) delete(name string) ! {
	mut p := zinit.get(name)!
	p.destroy()!
}

pub fn (mut self Zinit) load() ! {
	cmd := 'zinit list'
	mut res := os.execute(cmd)
	if res.exit_code > 0 {
		if res.output.contains('failed to connect') {
			res = os.execute(cmd)
			if res.exit_code > 0 {
				$if debug {
					print_backtrace()
				}
				return error("can't do zinit list, after start of zinit.\n${res}")
			}
		} else {
			$if debug {
				print_backtrace()
			}
			return error("can't do zinit list.\n${res}")
		}
	}
	mut state := ''
	for line in res.output.split_into_lines() {
		if line.starts_with('---') {
			state = 'ok'
			continue
		}
		if state == 'ok' && line.contains(':') {
			name := line.split(':')[0].to_lower().trim_space()
			mut zp := ZProcess{
				name: name
			}
			zp.load()!
			self.processes[name] = zp
		}
	}
}

pub fn (mut self Zinit) names() []string {
	return self.processes.keys()
}
