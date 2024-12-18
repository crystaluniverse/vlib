module osal

import time
import os
import math
// import freeflowuniverse.crystallib.ui.console

pub enum PMState {
	init
	ok
	old
}

@[heap]
pub struct ProcessMap {
pub mut:
	processes []ProcessInfo
	lastscan  time.Time
	state     PMState
	pids      []int
}

@[heap]
pub struct ProcessInfo {
pub mut:
	cpu_perc f32
	mem_perc f32
	cmd      string
	pid      int
	ppid     int // parentpid
	// resident memory
	rss int
}

// make sure to use new first, so that the connection has been initted
// then you can get it everywhere
pub fn processmap_get() !ProcessMap {
	mut pm := ProcessMap{}
	pm.scan()!
	return pm
}

// get process info from 1 specific process
// returns
//```
// pub struct ProcessInfo {
// pub mut:
// 	cpu_perc	f32
// 	mem_perc	f32
// 	cmd 		string
// 	pid 		int
// 	ppid 		int
// 	//resident memory
// 	rss			int
// }
//```
pub fn processinfo_get(pid int) !ProcessInfo {
	mut pm := processmap_get()!
	for pi in pm.processes {
		if pi.pid == pid {
			return pi
		}
	}
	return error('Cannot find process with pid: ${pid}, to get process info from.')
}

pub fn processinfo_get_byname(name string) ![]ProcessInfo {
	mut pm := processmap_get()!
	mut res := []ProcessInfo{}
	for pi in pm.processes {
		// console.print_debug(pi.cmd)
		if pi.cmd.contains(name) {
			if pi.cmd.starts_with('sudo ') {
				continue
			}
			if pi.cmd.to_lower().starts_with('screen ') {
				continue
			}
			res << pi
		}
	}
	return res
}

pub fn process_exists_byname(name string) !bool {
	res := processinfo_get_byname(name)!
	return res.len > 0
}

pub fn process_exists(pid int) bool {
	r := os.execute('kill -0 ${pid}')
	if r.exit_code > 0 {
		// return error('could not execute kill -0 ${pid}')
		return false
	}
	return true
}

// return the process and its children
pub fn processinfo_with_children(pid int) !ProcessMap {
	mut pi := processinfo_get(pid)!
	mut res := processinfo_children(pid)!
	res.processes << pi
	return res
}

// get all children of 1 process
pub fn processinfo_children(pid int) !ProcessMap {
	mut pm := processmap_get()!
	mut res := []ProcessInfo{}
	pm.children_(mut res, pid)!
	return ProcessMap{
		processes: res
		lastscan:  pm.lastscan
		state:     pm.state
	}
}

@[params]
pub struct ProcessKillArgs {
pub mut:
	name string
	pid  int
}

// kill process and all the ones underneith
pub fn process_kill_recursive(args ProcessKillArgs) ! {
	if args.name.len > 0 {
		for pi in processinfo_get_byname(args.name)! {
			process_kill_recursive(pid: pi.pid)!
		}
		return
	}
	if args.pid == 0 {
		return error('need to specify pid or name')
	}
	if process_exists(args.pid) {
		pm := processinfo_with_children(args.pid)!
		for p in pm.processes {
			os.execute('kill -9 ${p.pid}')
		}
	}
}

fn (pm ProcessMap) children_(mut result []ProcessInfo, pid int) ! {
	// console.print_debug("children: $pid")
	for p in pm.processes {
		if p.ppid == pid {
			// console.print_debug("found parent: ${p}")
			if result.filter(it.pid == p.pid).len == 0 {
				result << p
				pm.children_(mut result, p.pid)! // find children of the one we found
			}
		}
	}
}

pub fn (mut p ProcessInfo) str() string {
	x := math.min(60, p.cmd.len)
	subst := p.cmd.substr(0, x)
	return 'pid:${p.pid:-7} parent:${p.ppid:-7} cmd:${subst}'
}

fn (mut pm ProcessMap) str() string {
	mut out := ''
	for p in pm.processes {
		out += '${p}\n'
	}
	return out
}

fn (mut pm ProcessMap) scan() ! {
	now := time.now().unix()
	// only scan if we didn't do in last 5 seconds
	if pm.lastscan.unix() > now - 5 {
		// means scan is ok
		if pm.state == PMState.ok {
			return
		}
	}

	cmd := 'ps ax -o pid,ppid,stat,%cpu,%mem,rss,command'
	res := os.execute(cmd)

	if res.exit_code > 0 {
		return error('Cannot get process info \n${cmd}')
	}

	pm.processes = []ProcessInfo{}

	// console.print_debug("DID SCAN")
	for line in res.output.split_into_lines() {
		if !line.contains('PPID') {
			mut fields := line.fields()
			if fields.len < 6 {
				// console.print_debug(res)
				// console.print_debug("SSS")
				// console.print_debug(line)
				// panic("ss")
				continue
			}
			mut pi := ProcessInfo{}
			pi.pid = fields[0].int()
			pi.ppid = fields[1].int()
			pi.cpu_perc = fields[3].f32()
			pi.mem_perc = fields[4].f32()
			pi.rss = fields[5].int()
			fields.delete_many(0, 6)
			pi.cmd = fields.join(' ')
			// console.print_debug(pi.cmd)
			if pi.pid !in pm.pids {
				pm.processes << pi
				pm.pids << pi.pid
			}
		}
	}

	pm.lastscan = time.now()
	pm.state = PMState.ok

	// console.print_debug(pm)
}

pub fn whoami() !string {
	res := os.execute('whoami')
	if res.exit_code > 0 {
		return error('Could not do whoami\n${res}')
	}
	return res.output.trim_space()
}
