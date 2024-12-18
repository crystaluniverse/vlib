module systemd

// import os
import maps
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import os

pub fn testsuite_begin() ! {
	mut systemdfactory := new()!
	mut process := systemdfactory.new(
		cmd:   'redis-server'
		name:  'testservice'
		start: false
	)!

	process.delete()!
}

pub fn testsuite_end() ! {
	mut systemdfactory := new()!
	mut process := systemdfactory.new(
		cmd:   'redis-server'
		name:  'testservice'
		start: false
	)!

	process.delete()!
}

pub fn test_systemd_process_status() ! {
	mut systemdfactory := new()!
	mut process := systemdfactory.new(
		cmd:   'redis-server'
		name:  'testservice'
		start: false
	)!

	process.start()!
	status := process.status()!
	assert status == .active
}

pub fn test_parse_systemd_process_status() ! {
	output := 'testservice.service - testservice
     Loaded: loaded (/etc/systemd/system/testservice.service; enabled; preset: disabled)
     Active: active (running) since Mon 2024-06-10 12:51:24 CEST; 2ms ago
   Main PID: 202537 (redis-server)
      Tasks: 1 (limit: 154455)
     Memory: 584.0K (peak: 584.0K)
        CPU: 0
     CGroup: /system.slice/testservice.service
             └─202537 redis-server

Jun 10 12:51:24 myhost1 systemd[1]: testservice.service: Scheduled restart job, restart counter is at 1.
Jun 10 12:51:24 myhost1 systemd[1]: Started testservice.'

	status := parse_systemd_process_status(output)
	assert status == .active
}
