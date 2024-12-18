module tmux

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.installers.tmux

// fn testsuite_end() {

// 	
// }

fn testsuite_begin() {
	mut tmux := Tmux{}

	if tmux.is_running()! {
		tmux.stop()!
	}
}

fn test_session_create() {
	// installer := tmux.get_install(
	// 	panic('could not install tmux: ${err}')
	// }

	mut tmux := Tmux{}
	tmux.start() or { panic('cannot start tmux: ${err}') }

	mut s := Session{
		tmux:    &tmux
		windows: map[string]&Window{}
		name:    'testsession'
	}

	mut s2 := Session{
		tmux:    &tmux
		windows: map[string]&Window{}
		name:    'testsession2'
	}

	// test testsession exists after session_create
	mut tmux_ls := osal.execute_silent('tmux ls') or { panic("can't exec: ${err}") }
	assert !tmux_ls.contains('testsession: 1 windows')
	s.create() or { panic('Cannot create session: ${err}') }
	tmux_ls = osal.execute_silent('tmux ls') or { panic("can't exec: ${err}") }
	assert tmux_ls.contains('testsession: 1 windows')

	// test multiple session_create for same tmux
	tmux_ls = osal.execute_silent('tmux ls') or { panic("can't exec: ${err}") }
	assert !tmux_ls.contains('testsession2: 1 windows')
	s2.create() or { panic('Cannot create session: ${err}') }
	tmux_ls = osal.execute_silent('tmux ls') or { panic("can't exec: ${err}") }
	assert tmux_ls.contains('testsession2: 1 windows')

	// test session_create with duplicate session
	mut create_err := ''
	s2.create() or { create_err = err.msg() }
	assert create_err != ''
	assert create_err.contains('duplicate session: testsession2')
	tmux_ls = osal.execute_silent('tmux ls') or { panic("can't exec: ${err}") }
	assert tmux_ls.contains('testsession2: 1 windows')

	s.stop() or { panic('Cannot stop session: ${err}') }
	s2.stop() or { panic('Cannot stop session: ${err}') }
}

// fn test_session_stop() {

// 	
// 	installer := tmux.get_install(

// 	mut tmux := Tmux {
// 		node: node_ssh
// 	}

// 	mut s := Session{
// 		tmux: &tmux // reference back
// 		windows: map[string]&Window{}
// 		name: 'testsession3'
// 	}

// 	s.create() or  { panic("Cannot create session: $err") }
// 	mut tmux_ls := osal.execute_silent('tmux ls') or { panic("can't exec: $err") }
// 	assert tmux_ls.contains("testsession3: 1 windows")
// 	s.stop() or  { panic("Cannot stop session: $err")}
// 	tmux_ls = osal.execute_silent('tmux ls') or { panic("can't exec: $err") }
// 	assert !tmux_ls.contains("testsession3: 1 windows")
// }
