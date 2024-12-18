module tmux

import os
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.data.ourtime
import time
import freeflowuniverse.crystallib.ui.console

@[heap]
struct Window {
pub mut:
	session &Session @[skip]
	name    string
	id      int
	active  bool
	pid     int
	paneid  int
	cmd     string
	env     map[string]string
}

pub struct WindowArgs {
pub mut:
	name  string
	cmd   string
	env   map[string]string
	reset bool
}

// window_name is the name of the window in session main (will always be called session main)
// cmd to execute e.g. bash file
// environment arguments to use
// reset, if reset it will create window even if it does already exist, will destroy it
// ```
// struct WindowArgs {
// pub mut:
// 	name    string
// 	cmd		string
// 	env		map[string]string	
// 	reset	bool
// }
// ```
pub fn (mut t Tmux) window_new(args WindowArgs) !Window {
	mut s := t.session_create(name: 'main', reset: false)!
	mut w := s.window_new(args)!
	return w
}

// is always in the main tmux
pub fn (mut t Tmux) window_delete(args WindowGetArgs) ! {
	mut s := t.session_create(name: 'main', reset: false)!
	s.window_delete(name: args.name)!
}

// window_name is the name of the window in session main (will always be called session main)
// cmd to execute e.g. bash file
// environment arguments to use
// reset, if reset it will create window even if it does already exist, will destroy it
// ```
// struct WindowArgs {
// pub mut:
// 	name    string
// 	cmd		string
// 	env		map[string]string	
// 	reset	bool
// }
// ```
pub fn (mut s Session) window_new(args WindowArgs) !Window {
	$if debug {
		console.print_header(' start window: \n${args}')
	}
	namel := texttools.name_fix(args.name)
	if s.window_exist(name: namel) {
		if args.reset {
			s.window_delete(name: namel)!
		} else {
			return error('cannot create new window it already exists, window ${namel} in session:${s.name}')
		}
	}
	mut w := Window{
		session: &s
		name:    namel
		cmd:     args.cmd
		env:     args.env
	}
	s.windows << &w
	w.create()!
	s.window_delete(name: 'notused')!
	return w
}

pub struct WindowGetArgs {
pub mut:
	name string
	cmd  string
	id   int
}

fn (mut s Session) window_exist(args_ WindowGetArgs) bool {
	mut args := args_
	s.window_get(args) or { return false }
	return true
}

pub fn (mut s Session) window_get(args_ WindowGetArgs) !&Window {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	for w in s.windows {
		if w.name == args.name {
			if (args.id > 0 && w.id == args.id) || args.id == 0 {
				return w
			}
		}
	}
	return error('Cannot find window ${args.name} in session:${s.name}')
}

pub fn (mut s Session) window_delete(args_ WindowGetArgs) ! {
	// $if debug { console.print_debug(" - window delete: $args_")}
	mut args := args_
	args.name = texttools.name_fix(args.name)
	if !(s.window_exist(args)) {
		return
	}
	mut i := 0
	for mut w in s.windows {
		if w.name == args.name {
			if (args.id > 0 && w.id == args.id) || args.id == 0 {
				w.stop()!
				break
			}
		}
		i += 1
	}
	s.windows.delete(i) // i is now the one in the list which needs to be removed	
}

pub fn (mut w Window) create() ! {
	// tmux new-window -P -c /tmp -e good=1 -e bad=0 -n koekoe -t main bash
	if w.cmd.contains('\n') {
		// means is multiline need to write it
		// scriptpath         string // is the path where the script will be put which is executed
		// scriptkeep         bool   // means we don't remove the script
		os.mkdir_all('/tmp/tmux/${w.session.name}')!
		cmd_new := osal.exec_string(
			cmd:        w.cmd
			scriptpath: '/tmp/tmux/${w.session.name}/${w.name}.sh'
			scriptkeep: true
		)!
		w.cmd = cmd_new
	}

	// console.print_debug(w)

	if w.active == false {
		res_opt := "-P -F '#{session_name}|#{window_name}|#{window_id}|#{pane_active}|#{pane_id}|#{pane_pid}|#{pane_start_command}'"
		cmd := 'tmux new-window  ${res_opt} -t ${w.session.name} -n ${w.name} \'/bin/bash -c ${w.cmd}\''
		console.print_debug(cmd)
		res := osal.exec(cmd: cmd, stdout: false, name: 'tmux_window_create') or {
			return error("Can't create new window ${w.name} \n${cmd}\n${err}")
		}
		// now look at output to get the window id = wid
		line_arr := res.output.split('|')
		wid := line_arr[2] or { panic('cannot split line for window create.\n${line_arr}') }
		w.id = wid.replace('@', '').int()
		$if debug {
			console.print_header(' WINDOW - Window: ${w.name} created in session: ${w.session.name}')
		}
	} else {
		return error('cannot create window, it already exists.\n${w.name}:${w.id}:${w.cmd}')
	}
}

// do some good checks if the window is still active
// not implemented yet
pub fn (mut w Window) check() ! {
	panic('not implemented yet')
}

// restart the window
pub fn (mut w Window) restart() ! {
	w.stop()!
	w.create()!
}

// stop the window
pub fn (mut w Window) stop() ! {
	osal.exec(
		cmd:    'tmux kill-window -t @${w.id}'
		stdout: false
		name:   'tmux_kill-window'
		die:    false
	) or { return error("Can't kill window with id:${w.id}") }
	w.pid = 0
	w.active = false
}

pub fn (window Window) str() string {
	return ' - name:${window.name} wid:${window.id} active:${window.active} pid:${window.pid} cmd:${window.cmd}'
}

// will select the current window so with tmux a we can go there .
// to login into a session do `tmux a -s mysessionname`
fn (mut w Window) activate() ! {
	cmd2 := 'tmux select-window -t %${w.id}'
	osal.execute_silent(cmd2) or {
		return error("Couldn't select window ${w.name} \n${cmd2}\n${err}")
	}
}

// show the environment
pub fn (mut w Window) environment_print() ! {
	res := osal.execute_silent('tmux show-environment -t %${w.paneid}') or {
		return error('Couldnt show enviroment cmd: ${w.cmd} \n${err}')
	}
	os.log(res)
}

// capture the output
pub fn (mut w Window) output_print() ! {
	o := w.output()!
	console.print_debug(o)
}

// capture the output
pub fn (mut w Window) output() !string {
	//-S is start, minus means go in history, otherwise its only the active output
	// tmux capture-pane -t your-session-name:your-window-number -S -1000
	cmd := 'tmux capture-pane -t ${w.session.name}:@${w.id} -S -1000 && tmux show-buffer'
	res := osal.execute_silent(cmd) or {
		return error('Couldnt show enviroment cmd: ${w.cmd} \n${err}')
	}
	return texttools.remove_empty_lines(res)
}

pub fn (mut w Window) output_wait(c_ string, timeoutsec int) ! {
	mut t := ourtime.now()
	start := t.unix()
	c := c_.replace('\n', '')
	for i in 0 .. 2000 {
		o := w.output()!
		// console.print_debug(o)
		$if debug {
			console.print_debug(" - tmux ${w.name}: wait for: '${c}'")
		}
		// need to replace \n because can be wrapped because of size of pane
		if o.replace('\n', '').contains(c) {
			return
		}
		mut t2 := ourtime.now()
		if t2.unix() > start + timeoutsec {
			return error('timeout on output wait for tmux.\n${w} .\nwaiting for:\n${c}')
		}
		time.sleep(100 * time.millisecond)
	}
}
