module tmux

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.ui.console

fn (mut t Tmux) scan_add(line string) !&Window {
	// console.print_debug(" -- scan add: $line")
	if line.count('|') < 4 {
		return error(@FN + 'expects line with at least 5 params separated by |')
	}

	line_arr := line.split('|')
	session_name := line_arr[0]
	window_name := line_arr[1]
	window_id := line_arr[2]
	pane_active := line_arr[3]
	pane_id := line_arr[4]
	pane_pid := line_arr[5]
	pane_start_command := line_arr[6] or { '' }

	wid := (window_id.replace('@', '')).int()

	// os.log('TMUX FOUND: $line\n    ++ $session_name:$window_name wid:$window_id pid:$pane_pid entrypoint:$pane_start_command')
	mut s := t.session_get(session_name)!

	mut active := false
	if pane_active == '1' {
		active = true
	}

	mut name := texttools.name_fix(window_name)

	mut w := Window{
		session: s
		name:    name
	}

	if !(s.window_exist(name: window_name, id: wid)) {
		// console.print_debug("window not exists")
		s.windows << &w
	} else {
		w = s.window_get(name: window_name, id: wid)!
	}

	w.id = wid
	w.active = active
	w.pid = pane_pid.int()
	w.paneid = (pane_id.replace('%', '')).int()
	w.cmd = pane_start_command

	return &w
}

// scan the system to detect sessions .
pub fn (mut t Tmux) scan() ! {
	// os.log('TMUX - Scanning ....')

	cmd_list_session := "tmux list-sessions -F '#{session_name}'"
	exec_list := osal.exec(cmd: cmd_list_session, stdout: false, name: 'tmux_list') or {
		return error('could not execute list sessions.\n${err}')
	}

	// console.print_debug('execlist out for sessions: ${exec_list}')

	// make sure we have all sessions
	for line in exec_list.output.split_into_lines() {
		session_name := line.trim(' \n').to_lower()
		if session_name == '' {
			continue
		}
		if t.session_exist(session_name) {
			continue
		}
		mut s := Session{
			tmux: &t // reference back
			name: session_name
		}
		t.sessions << &s
	}

	console.print_debug(t)

	// mut done := map[string]bool{}
	cmd := "tmux list-panes -a -F '#{session_name}|#{window_name}|#{window_id}|#{pane_active}|#{pane_id}|#{pane_pid}|#{pane_start_command}'"
	out := osal.execute_silent(cmd) or { return error("Can't execute ${cmd} \n${err}") }

	// $if debug{console.print_debug('tmux list panes out:\n${out}')}

	for line in out.split_into_lines() {
		if line.contains('|') {
			t.scan_add(line)!
		}
	}
}
