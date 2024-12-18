module systemd

// import os
import maps
import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.ui.console
import os

@[heap]
pub struct SystemdProcess {
pub mut:
	name        string
	unit        string // as generated or used by systemd
	cmd         string
	pid         int
	env         map[string]string
	systemd     &Systemd @[skip; str: skip]
	description string
	info        SystemdProcessInfo
	restart     bool = true // whether process will be restarted upon failure
}

pub fn (mut self SystemdProcess) servicefile_path() string {
	return '${self.systemd.path.path}/${self.name}.service'
}

pub fn (mut self SystemdProcess) write() ! {
	mut p := pathlib.get_file(path: self.servicefile_path(), create: true)!
	console.print_header(' systemd write service: ${p.path}')

	envs_lst := maps.to_array[string, string, string](self.env, fn (k string, v string) string {
		return 'Environment=${k}=${v}'
	})

	envs := envs_lst.join('\n')

	servicecontent := $tmpl('templates/service.yaml')

	println(self)
	println(servicecontent)

	p.write(servicecontent)!
}

pub fn (mut self SystemdProcess) start() ! {
	console.print_header('starting systemd process: ${self.name}')
	// self.write()!
	cmd := '
	systemctl daemon-reload
	systemctl enable ${self.name}
	systemctl start ${self.name}
	' // console.print_debug(cmd)

	_ = osal.execute_silent(cmd)!
	self.refresh()!
}

// get status from system
pub fn (mut self SystemdProcess) refresh() ! {
	self.systemd.load()!
	systemdobj2 := self.systemd.get(self.name)!
	self.info = systemdobj2.info
	self.description = systemdobj2.description
	self.name = systemdobj2.name
	self.unit = systemdobj2.unit
	self.cmd = systemdobj2.cmd
}

pub fn (mut self SystemdProcess) delete() ! {
	console.print_header('Process systemd: ${self.name} delete.')
	self.stop()!
	if os.exists(self.servicefile_path()) {
		os.rm(self.servicefile_path())!
	}
}

pub fn (mut self SystemdProcess) stop() ! {
	cmd := '
	set +ex
	systemctl daemon-reload
	systemctl disable ${self.name}
	systemctl stop ${self.name}
	'
	_ = osal.exec(cmd: cmd, stdout: false, debug: false, ignore_error: false)!
	self.systemd.load()!
}

pub fn (mut self SystemdProcess) restart() ! {
	cmd := '
	systemctl daemon-reload
	systemctl restart ${self.name}
	'
	_ = osal.execute_silent(cmd)!
	self.systemd.load()!
}

enum SystemdStatus {
	unknown
	active
	inactive
	failed
	activating
	deactivating
}

pub fn (self SystemdProcess) status() !SystemdStatus {
	// exit with 3 is converted to exit with 0
	cmd := '
	systemctl daemon-reload
	systemctl status --no-pager --lines=0 ${name_fix(self.name)}
	'
	job := osal.exec(cmd: cmd, stdout: false) or {
		if err.code() == 3 {
			if err is osal.JobError {
				return parse_systemd_process_status(err.job.output)
			}
		}
		return error('Failed to run command to get status ${err}')
	}

	return parse_systemd_process_status(job.output)
}

fn parse_systemd_process_status(output string) SystemdStatus {
	lines := output.split_into_lines()
	for line in lines {
		if line.contains('Active: ') {
			if line.contains('active (running)') {
				return .active
			} else if line.contains('inactive (dead)') {
				return .inactive
			} else if line.contains('failed') {
				return .failed
			} else if line.contains('activating') {
				return .activating
			} else if line.contains('deactivating') {
				return .deactivating
			}
		}
	}
	return .unknown
}
