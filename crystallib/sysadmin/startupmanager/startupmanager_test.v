module startupmanager

import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.osal.screen
import freeflowuniverse.crystallib.osal.systemd

const process_name = 'testprocess'

pub fn testsuite_begin() ! {
	mut sm := get()!
	if sm.exists(process_name)! {
		sm.stop(process_name)!
	}
}

pub fn testsuite_end() ! {
	mut sm := get()!
	if sm.exists(process_name)! {
		sm.stop(process_name)!
	}
}

// remove from the startup manager
pub fn test_status() ! {
	mut sm := get()!

	sm.start(
		name: process_name
		cmd:  'redis-server'
	)!

	status := sm.status(process_name)!
	assert status == .active
}
