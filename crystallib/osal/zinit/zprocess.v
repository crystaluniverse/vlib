module zinit

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.data.ourtime
import freeflowuniverse.crystallib.ui.console
import time

pub struct ZProcess {
pub:
	name string = 'default'
pub mut:
	cmd         string // command to start
	cmd_stop    string // command to stop (optional)
	cmd_test    string // command line to test service is running
	workdir     string // where to execute the commands
	status      ZProcessStatus
	pid         int
	after       []string // list of service we depend on
	env         map[string]string
	oneshot     bool
	start       bool = true
	restart     bool = true // whether the process should be restarted on failure
	description string // not used in zinit
}

pub enum ZProcessStatus {
	unknown
	init
	ok
	killed
	error
	blocked
	spawned
}

pub enum StartupManagerType {
	unknown
	zinit
	systemd
	screen
}

@[params]
pub struct ZProcessNewArgs {
pub mut:
	name        string @[required]
	cmd         string @[required]
	cmd_stop    string   // command to stop (optional)
	cmd_test    string   // command line to test service is running
	workdir     string   // where to execute the commands
	after       []string // list of service we depend on
	env         map[string]string
	oneshot     bool
	start       bool = true
	restart     bool = true // whether the process should be restarted on failure
	description string // not used in zinit
	startuptype StartupManagerType
}

pub fn (zp ZProcess) cmd() !string {
	mut zinitobj := new()!
	mut path := zinitobj.pathcmds.file_get_new('${zp.name}_start.sh')!
	if path.exists() {
		return 'bash -c \'${path.path}\''
	} else {
		if zp.cmd.contains('\n') {
			return error('cmd cannot have \\n and not have cmd file on disk on ${path.path}')
		}
		if zp.cmd == '' {
			return error('cmd cannot be empty')
		}
	}
	return '${zp.cmd}'
}

pub fn (zp ZProcess) cmdtest() !string {
	mut zinitobj := new()!
	mut path := zinitobj.pathcmds.file_get_new('${zp.name}_test.sh')!
	if path.exists() {
		return "bash -c \"${path.path}\""
	} else {
		if zp.cmd_test.contains('\n') {
			return error('cmd test cannot have \\n and not have cmd file on disk on ${path.path}')
		}
		if zp.cmd_test == '' {
			return error('cmd test cannot be empty')
		}
	}
	return '${zp.cmd_test}'
}

pub fn (zp ZProcess) cmdstop() !string {
	mut zinitobj := new()!
	mut path := zinitobj.pathcmds.file_get_new('${zp.name}_stop.sh')!
	if path.exists() {
		return "bash -c \"${path.path}\""
	} else {
		if zp.cmd_stop.contains('\n') {
			return error('cmd stop cannot have \\n and not have cmd file on disk on ${path.path}')
		}
		if zp.cmd_stop == '' {
			return error('cmd stop cannot be empty')
		}
	}
	return '${zp.cmd_stop}'
}

// return the configuration as needs to be given to zinit
fn (zp ZProcess) config_content() !string {
	mut out := "
exec: \"${zp.cmd()!}\"
signal:
  stop: SIGKILL
log: ring
"
	if zp.cmd_test.len > 0 {
		out += "test: \"${zp.cmdtest()!}\"\n"
	}
	if zp.oneshot {
		out += 'oneshot: true\n'
	}
	if zp.after.len > 0 {
		out += 'after:\n'
		for val in zp.after {
			out += '  - ${val}\n'
		}
	}
	if zp.env.len > 0 {
		out += 'env:\n'
		for key, val in zp.env {
			out += '  ${key}: \'${val}\'\n'
		}
	}
	return out
}

pub fn (zp ZProcess) start() ! {
	console.print_header(' start ${zp.name}')
	mut client := new_rpc_client()
	if !client.isloaded(zp.name) {
		client.monitor(zp.name)! // means will check it out
	}
}

pub fn (mut zp ZProcess) stop() ! {
	console.print_header(' stop ${zp.name}')
	st := zp.status()!

	// QUESTION: removed error, since those can also be stopped
	// otherwise fails to forget the zp when destroying
	if st in [.unknown, .killed] {
		return
	}
	mut client := new_rpc_client()
	client.stop(zp.name)!
	zp.status()!
}

pub fn (mut zp ZProcess) destroy() ! {
	console.print_header(' destroy ${zp.name}')
	zp.stop()!
	// return error('ssssa')
	mut client := new_rpc_client()
	client.forget(zp.name) or {}
	mut zinit_obj := new()!
	mut path1 := zinit_obj.pathcmds.file_get_new('${zp.name}_start.sh')!
	mut path2 := zinit_obj.pathcmds.file_get_new('${zp.name}_stop.sh')!
	mut path3 := zinit_obj.pathcmds.file_get_new('${zp.name}_test.sh')!
	mut pathyaml := zinit_obj.path.file_get_new(zp.name + '.yaml')!
	path1.delete()!
	path2.delete()!
	path3.delete()!
	pathyaml.delete()!
}

// how long to wait till the specified output shows up, timeout in sec
pub fn (mut zp ZProcess) output_wait(c_ string, timeoutsec int) ! {
	zp.start()!
	_ = new_rpc_client()
	zp.check()!
	mut t := ourtime.now()
	start := t.unix()
	c := c_.replace('\n', '')
	for _ in 0 .. 2000 {
		o := zp.log()!
		console.print_debug(o)
		$if debug {
			console.print_debug(" - zinit ${zp.name}: wait for: '${c}'")
		}
		// need to replace \n because can be wrapped because of size of pane
		if o.replace('\n', '').contains(c) {
			return
		}
		mut t2 := ourtime.now()
		if t2.unix() > start + timeoutsec {
			return error('timeout on output wait for zinit.\n${zp.name} .\nwaiting for:\n${c}')
		}
		time.sleep(100 * time.millisecond)
	}
}

// check if process is running if yes return the log
pub fn (zp ZProcess) log() !string {
	assert zp.name.len > 2
	cmd := 'zinit log ${zp.name} -s'
	res := os.execute(cmd)
	if res.exit_code > 0 {
		$if debug {
			print_backtrace()
		}
		return error('zprocesslog: could not execute ${cmd}')
	}
	mut out := []string{}

	for line in res.output.split_into_lines() {
		if line.contains('=== START ========') {
			out = []string{}
		}
		out << line
	}

	return out.join_lines()
}

// return status of process
//```
// enum ZProcessStatus {
// 	unknown
// 	init
// 	ok
// 	error
// 	blocked
// 	spawned
// killed
// }
//```
pub fn (mut zp ZProcess) status() !ZProcessStatus {
	cmd := 'zinit status ${zp.name}'
	r := osal.execute_silent(cmd)!
	for line in r.split_into_lines() {
		if line.starts_with('pid') {
			zp.pid = line.split('pid:')[1].trim_space().int()
		}
		if line.starts_with('state') {
			st := line.split('state:')[1].trim_space().to_lower()
			// console.print_debug(" status string: $st")	
			if st.contains('sigkill') {
				zp.status = .killed
			} else if st.contains('error') {
				zp.status = .error
			} else if st.contains('spawned') {
				zp.status = .error
			} else if st.contains('running') {
				zp.status = .ok
			} else {
				zp.status = .unknown
			}
		}
	}
	// mut client := new_rpc_client()
	// st := client.status(zp.name) or {return .unknown}
	// statusstr:=st.state.to_lower()
	// if statusstr=="running"{
	// 	zp.status = .ok
	// }else if statusstr.contains("error"){
	// 	zp.status = .error
	// }else{
	// 	console.print_debug(st)
	// 	return error("status not implemented yet")
	// }
	return zp.status
}

// will check that process is running
pub fn (mut zp ZProcess) check() ! {
	status := zp.status()!
	if status != .ok {
		return error('process is not running.\n${zp}')
	}
}

// will check that process is running
pub fn (mut zp ZProcess) isrunning() !bool {
	status := zp.status()!
	if status != .ok {
		return false
	}
	return true
}
