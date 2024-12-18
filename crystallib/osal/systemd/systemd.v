module systemd

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console

__global (
	systemd_global []&Systemd
)

@[heap]
pub struct Systemd {
pub mut:
	processes []&SystemdProcess
	path      pathlib.Path
	path_cmd  pathlib.Path
	status    SystemdFactoryStatus
}

pub enum SystemdFactoryStatus {
	init
	ok
	error
}

pub fn new() !&Systemd {
	if systemd_global.len > 0 {
		return systemd_global[0]
	}
	mut systemd := Systemd{
		path:     pathlib.get_dir(path: '/etc/systemd/system', create: false)!
		path_cmd: pathlib.get_dir(path: '/etc/systemd_cmds', create: true)!
	}
	systemd.load()!
	systemd_global << &systemd
	return systemd_global[0]
}

// check if systemd is on system, returns True if yes
pub fn check() !bool {
	if !osal.cmd_exists('systemctl') {
		return false
	}

	return osal.execute_ok('systemctl status --no-pager')
}

fn (mut systemd Systemd) load() ! {
	if systemd.status == .ok {
		return
	}
	console.print_header('Systemd load')
	osal.execute_silent('systemctl daemon-reload')!
	systemd.processes = []&SystemdProcess{}
	for item in process_list()! {
		mut sdprocess := SystemdProcess{
			description: item.description
			systemd:     &systemd
			unit:        item.unit
			info:        item
		}
		systemd.setinternal(mut sdprocess)
	}

	systemd.status = .ok
}

pub fn (mut systemd Systemd) reload() ! {
	systemd.status = .init
	systemd.load()!
}

@[params]
pub struct SystemdProcessNewArgs {
pub mut:
	name        string @[required]
	cmd         string @[required]
	description string
	env         map[string]string
	start       bool = true
	restart     bool = true
}

//```
// name      string            @[required]
// cmd       string            @[required]
// description string @[required]
//```
pub fn (mut systemd Systemd) new(args_ SystemdProcessNewArgs) !SystemdProcess {
	mut args := args_
	args.name = name_fix(args.name)

	if args.cmd == '' {
		return error('cmd needs to be filled in in:\n${args}')
	}

	mut sdprocess := SystemdProcess{
		name:        args.name
		description: args.description
		cmd:         args.cmd
		restart:     true
		systemd:     &systemd
		info:        SystemdProcessInfo{
			unit: args.name
		}
	}

	// TODO: maybe systemd can start multiline scripts?
	if args.cmd.contains('\n') {
		// means we can load the special cmd
		mut pathcmd := systemd.path_cmd.file_get_new('${args.name}_cmd')!
		pathcmd.write(sdprocess.cmd)!
		pathcmd.chmod(0o750)!
		sdprocess.cmd = '/bin/bash -c ${pathcmd.path}'
	}
	sdprocess.env = args.env.move()

	sdprocess.write()!
	systemd.setinternal(mut sdprocess)

	if args.start || args.restart {
		sdprocess.stop()!
	}

	if args.start {
		sdprocess.start()!
	}

	return sdprocess
}

pub fn (mut systemd Systemd) names() []string {
	r := systemd.processes.map(it.name)
	return r
}

fn (mut systemd Systemd) setinternal(mut sdprocess SystemdProcess) {
	sdprocess.name = name_fix(sdprocess.info.unit)
	systemd.processes = systemd.processes.filter(it.name != sdprocess.name)
	systemd.processes << &sdprocess
}

pub fn (mut systemd Systemd) get(name_ string) !&SystemdProcess {
	name := name_fix(name_)
	if systemd.processes.len == 0 {
		systemd.load()!
	}
	for item in systemd.processes {
		if name_fix(item.name) == name {
			return item
		}
	}
	return error("Can't find systemd process with name ${name}, maybe reload the state with systemd.load()")
}

pub fn (mut systemd Systemd) exists(name_ string) bool {
	name := name_fix(name_)
	for item in systemd.processes {
		if name_fix(item.name) == name {
			return true
		}
	}
	return false
}

pub fn (mut systemd Systemd) destroy(name_ string) ! {
	for i, mut pr in systemd.processes {
		if name_fix(pr.name) == name_fix(name_) {
			pr.delete()!
			systemd.processes[i] = systemd.processes[systemd.processes.len - 1]
			systemd.processes.delete_last()
			break
		}
	}
}

fn name_fix(name_ string) string {
	mut name := texttools.name_fix(name_)
	if name.contains('.service') {
		name = name.all_before_last('.')
	}
	return name
}
