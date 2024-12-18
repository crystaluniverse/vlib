module zinit

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.systemd
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console
import os

@[heap]
pub struct Zinit {
pub mut:
	processes map[string]ZProcess
	path      pathlib.Path
	pathcmds  pathlib.Path
	pathtests pathlib.Path
}

@[params]
struct InitDProcGet {
	delete bool
	start  bool = true
}

@[params]
pub struct ZProcessNewArgs {
pub mut:
	name      string @[required]
	cmd       string @[required]
	cmd_file  bool // if we wanna force to run it as a file which is given to bash -c  (not just a cmd in zinit)
	test      string
	test_file bool
	after     []string
	env       map[string]string
	oneshot   bool
	start     bool = true
}

// start  it with systemd, because the zinit by itself needs to run somewhere
fn initd_proc_get(args InitDProcGet) !systemd.SystemdProcess {
	mut initdfactory := systemd.new()!
	mut initdprocess := initdfactory.new(
		cmd:         '/usr/local/bin/zinit init'
		name:        'zinit'
		description: 'a super easy to use startup manager.'
	)!
	// if args.delete {
	// 	initdprocess.remove()!
	// }
	// if args.start {
	// 	initdprocess.start()!
	// }
	return initdprocess
}
