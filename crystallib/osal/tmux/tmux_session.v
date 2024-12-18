module tmux

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.texttools
import os
import freeflowuniverse.crystallib.ui.console

@[heap]
struct Session {
pub mut:
	tmux    &Tmux @[str: skip] // reference back
	windows []&Window // session has windows
	name    string
}

// get session (session has windows) .
// returns none if not found
pub fn (mut t Tmux) session_get(name_ string) !&Session {
	name := texttools.name_fix(name_)
	for s in t.sessions {
		if s.name == name {
			return s
		}
	}
	return error('Can not find session with name: \'${name_}\', out of loaded sessions.')
}

pub fn (mut t Tmux) session_exist(name_ string) bool {
	name := texttools.name_fix(name_)
	t.session_get(name) or { return false }
	return true
}

pub fn (mut t Tmux) session_delete(name_ string) ! {
	if !(t.session_exist(name_)) {
		return
	}
	name := texttools.name_fix(name_)
	mut i := 0
	for mut s in t.sessions {
		if s.name == name {
			s.stop()!
			break
		}
		i += 1
	}
	t.sessions.delete(i)
}

@[params]
pub struct SessionCreateArgs {
pub mut:
	name  string @[required]
	reset bool
}

// create session, if reset will re-create
pub fn (mut t Tmux) session_create(args SessionCreateArgs) !&Session {
	name := texttools.name_fix(args.name)
	if !(t.session_exist(name)) {
		$if debug {
			console.print_header(' tmux - create session: ${args}')
		}
		mut s2 := Session{
			tmux: t // reference back
			name: name
		}
		s2.create()!
		t.sessions << &s2
	}
	mut s := t.session_get(name)!
	if args.reset {
		$if debug {
			console.print_header(' tmux - session ${name} will be restarted.')
		}
		s.restart()!
	}
	t.scan()!
	return s
}

pub fn (mut s Session) create() ! {
	res_opt := "-P -F '#\{window_id\}'"
	cmd := "tmux new-session ${res_opt} -d -s ${s.name} 'sh'"
	window_id_ := osal.execute_silent(cmd) or {
		return error("Can't create tmux session ${s.name} \n${cmd}\n${err}")
	}

	cmd3 := 'tmux set-option remain-on-exit on'
	osal.execute_silent(cmd3) or { return error("Can't execute ${cmd3}\n${err}") }

	window_id := window_id_.trim(' \n')
	cmd2 := "tmux rename-window -t ${window_id} 'notused'"
	osal.execute_silent(cmd2) or {
		return error("Can't rename window ${window_id} to notused \n${cmd2}\n${err}")
	}
}

pub fn (mut s Session) restart() ! {
	s.stop()!
	s.create()!
}

pub fn (mut s Session) stop() ! {
	osal.execute_silent('tmux kill-session -t ${s.name}') or {
		return error("Can't delete session ${s.name} - This may happen when session is not found: ${err}")
	}
}

// get all windows as found in a session
pub fn (mut s Session) windows_get() []&Window {
	mut res := []&Window{}
	// os.log('TMUX - Start listing  ....')
	for _, window in s.windows {
		res << window
	}
	return res
}

pub fn (mut s Session) windownames_get() []string {
	mut res := []string{}
	for _, window in s.windows {
		res << window.name
	}
	return res
}

pub fn (mut s Session) str() string {
	mut out := '## Session: ${s.name}\n\n'
	for _, w in s.windows {
		out += '${*w}\n'
	}
	return out
}

// pub fn (mut s Session) activate()! {	
// 	active_session := s.tmux.redis.get('tmux:active_session') or { 'No active session found' }
// 	if active_session != 'No active session found' && s.name != active_session {
// 		s.tmuxexecutor.db.exec('tmux attach-session -t $active_session') or {
// 			return error('Fail to attach to current active session: $active_session \n$err')
// 		}
// 		s.tmuxexecutor.db.exec('tmux switch -t $s.name') or {
// 			return error("Can't switch to session $s.name \n$err")
// 		}
// 		s.tmux.redis.set('tmux:active_session', s.name) or { panic('Failed to set tmux:active_session') }
// 		os.log('SESSION - Session: $s.name activated ')
// 	} else if active_session == 'No active session found' {
// 		s.tmux.redis.set('tmux:active_session', s.name) or { panic('Failed to set tmux:active_session') }
// 		os.log('SESSION - Session: $s.name activated ')
// 	} else {
// 		os.log('SESSION - Session: $s.name already activate ')
// 	}
// }
