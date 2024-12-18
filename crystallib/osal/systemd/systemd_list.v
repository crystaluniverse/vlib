module systemd

import os
import json

struct SystemdProcessInfoRaw {
	unit        string
	load        string
	active      string
	sub         string
	description string
}

pub struct SystemdProcessInfo {
pub mut:
	unit         string
	load_state   LoadState
	active_state ActiveState
	sub_state    SubState
	description  string
}

pub enum LoadState {
	loaded    // The unit's configuration file has been successfully loaded into memory.
	not_found // The unit's configuration file could not be found.
	error     // There was an error loading the unit's configuration file.
	masked    // The unit has been masked, which means it has been explicitly disabled and cannot be started.
}

pub enum ActiveState {
	active       // The unit has been started successfully and is running as expected.
	inactive     // The unit is not running.
	activating   // The unit is in the process of being started.
	deactivating // The unit is in the process of being stopped.
	failed       // The unit tried to start but failed.
}

// This provides more detailed information about the unit's state, often referred to as the "sub-state". This can vary significantly between different types of units (services, sockets, timers, etc.)
pub enum SubState {
	unknown
	start
	running // The service is currently running.
	exited  // The service has completed its process and exited. For services that do something at startup and then exit (oneshot services), this is a normal state.
	failed  // The service has failed after starting.
	waiting // The service is waiting for some condition to be met.
	autorestart
	dead
}

pub fn process_list() ![]SystemdProcessInfo {
	cmd := 'systemctl list-units --type=service --no-pager --all -o json-pretty '
	res_ := os.execute(cmd)
	if res_.exit_code > 0 {
		return error('could not execute: ${cmd}')
	}
	items := json.decode([]SystemdProcessInfoRaw, res_.output) or {
		panic('Failed to decode Systemd Process Info')
	}
	mut res := []SystemdProcessInfo{}
	for item in items {
		mut unit := SystemdProcessInfo{
			unit:        item.unit
			description: item.description
		}
		match item.load {
			'loaded' { unit.load_state = .loaded }
			'not-found' { unit.load_state = .not_found }
			'error' { unit.load_state = .error }
			'bad-setting' { unit.load_state = .error }
			'masked' { unit.load_state = .masked }
			else { return error('could not find right load state for systemd ${unit.load_state}') }
		}
		match item.active {
			'active' { unit.active_state = .active }
			'inactive' { unit.active_state = .inactive }
			'activating' { unit.active_state = .activating }
			'deactivating' { unit.active_state = .deactivating }
			'failed' { unit.active_state = .failed }
			else { return error('could not find right active state for systemd ${unit.load_state}') }
		}
		match item.sub {
			'start' { unit.sub_state = .start }
			'running' { unit.sub_state = .running }
			'exited' { unit.sub_state = .exited }
			'failed' { unit.sub_state = .failed }
			'waiting' { unit.sub_state = .waiting }
			'dead' { unit.sub_state = .dead }
			'auto-restart' { unit.sub_state = .autorestart }
			else { unit.sub_state = .unknown }
		}
		res << unit
	}
	return res
}
