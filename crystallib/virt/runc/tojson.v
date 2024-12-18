module runc

import json

// Helper functions to convert enums to strings
fn (cap Capability) str() string {
	return match cap {
		.cap_chown { 'CAP_CHOWN' }
		.cap_dac_override { 'CAP_DAC_OVERRIDE' }
		.cap_dac_read_search { 'CAP_DAC_READ_SEARCH' }
		.cap_fowner { 'CAP_FOWNER' }
		.cap_fsetid { 'CAP_FSETID' }
		.cap_kill { 'CAP_KILL' }
		.cap_setgid { 'CAP_SETGID' }
		.cap_setuid { 'CAP_SETUID' }
		.cap_setpcap { 'CAP_SETPCAP' }
		.cap_linux_immutable { 'CAP_LINUX_IMMUTABLE' }
		.cap_net_bind_service { 'CAP_NET_BIND_SERVICE' }
		.cap_net_broadcast { 'CAP_NET_BROADCAST' }
		.cap_net_admin { 'CAP_NET_ADMIN' }
		.cap_net_raw { 'CAP_NET_RAW' }
		.cap_ipc_lock { 'CAP_IPC_LOCK' }
		.cap_ipc_owner { 'CAP_IPC_OWNER' }
		.cap_sys_module { 'CAP_SYS_MODULE' }
		.cap_sys_rawio { 'CAP_SYS_RAWIO' }
		.cap_sys_chroot { 'CAP_SYS_CHROOT' }
		.cap_sys_ptrace { 'CAP_SYS_PTRACE' }
		.cap_sys_pacct { 'CAP_SYS_PACCT' }
		.cap_sys_admin { 'CAP_SYS_ADMIN' }
		.cap_sys_boot { 'CAP_SYS_BOOT' }
		.cap_sys_nice { 'CAP_SYS_NICE' }
		.cap_sys_resource { 'CAP_SYS_RESOURCE' }
		.cap_sys_time { 'CAP_SYS_TIME' }
		.cap_sys_tty_config { 'CAP_SYS_TTY_CONFIG' }
		.cap_mknod { 'CAP_MKNOD' }
		.cap_lease { 'CAP_LEASE' }
		.cap_audit_write { 'CAP_AUDIT_WRITE' }
		.cap_audit_control { 'CAP_AUDIT_CONTROL' }
		.cap_setfcap { 'CAP_SETFCAP' }
		.cap_mac_override { 'CAP_MAC_OVERRIDE' }
		.cap_mac_admin { 'CAP_MAC_ADMIN' }
		.cap_syslog { 'CAP_SYSLOG' }
		.cap_wake_alarm { 'CAP_WAKE_ALARM' }
		.cap_block_suspend { 'CAP_BLOCK_SUSPEND' }
		.cap_audit_read { 'CAP_AUDIT_READ' }
	}
}

fn (rlimit RlimitType) str() string {
	return match rlimit {
		.rlimit_cpu { 'RLIMIT_CPU' }
		.rlimit_fsize { 'RLIMIT_FSIZE' }
		.rlimit_data { 'RLIMIT_DATA' }
		.rlimit_stack { 'RLIMIT_STACK' }
		.rlimit_core { 'RLIMIT_CORE' }
		.rlimit_rss { 'RLIMIT_RSS' }
		.rlimit_nproc { 'RLIMIT_NPROC' }
		.rlimit_nofile { 'RLIMIT_NOFILE' }
		.rlimit_memlock { 'RLIMIT_MEMLOCK' }
		.rlimit_as { 'RLIMIT_AS' }
		.rlimit_lock { 'RLIMIT_LOCK' }
		.rlimit_sigpending { 'RLIMIT_SIGPENDING' }
		.rlimit_msgqueue { 'RLIMIT_MSGQUEUE' }
		.rlimit_nice { 'RLIMIT_NICE' }
		.rlimit_rtprio { 'RLIMIT_RTPRIO' }
		.rlimit_rttime { 'RLIMIT_RTTIME' }
	}
}

// Function to convert Capabilities struct to JSON
fn (cap Capabilities) to_json() map[string][]string {
	return {
		'bounding':    cap.bounding.map(it.str())
		'effective':   cap.effective.map(it.str())
		'inheritable': cap.inheritable.map(it.str())
		'permitted':   cap.permitted.map(it.str())
		'ambient':     cap.ambient.map(it.str())
	}
}

// Function to convert Rlimit struct to JSON
fn (rlimit Rlimit) to_json() map[string]json.Any {
	return {
		'type': rlimit.typ.str()
		'hard': rlimit.hard
		'soft': rlimit.soft
	}
}

// Example function to generate the Process JSON
fn generate_process_json(proc Process) string {
	// Convert the Process object to JSON
	process_json := {
		'terminal':     proc.terminal
		'user':         {
			'uid':            proc.user.uid
			'gid':            proc.user.gid
			'additionalGids': proc.user.additional_gids
		}
		'args':         proc.args
		'env':          proc.env
		'cwd':          proc.cwd
		'capabilities': proc.capabilities.to_json()
		'rlimits':      proc.rlimits.map(it.to_json())
	}

	// Convert the entire process map to JSON string
	return json.encode_pretty(process_json)
}

pub fn example_json() {
	// Example instantiation using enums and Process structure
	user := User{
		uid:             1000
		gid:             1000
		additional_gids: [1001, 1002]
	}

	capabilities := Capabilities{
		bounding:    [Capability.cap_chown, Capability.cap_dac_override]
		effective:   [Capability.cap_chown]
		inheritable: []
		permitted:   [Capability.cap_chown]
		ambient:     []
	}

	rlimits := [
		Rlimit{
			typ:  RlimitType.rlimit_nofile
			hard: 1024
			soft: 1024
		},
		Rlimit{
			typ:  RlimitType.rlimit_cpu
			hard: 1000
			soft: 500
		},
	]

	process := Process{
		terminal:     true
		user:         user
		args:         ['/bin/bash']
		env:          ['PATH=/usr/bin']
		cwd:          '/'
		capabilities: capabilities
		rlimits:      rlimits
	}

	// Generate the JSON for Process object
	json_output := generate_process_json(process)
	println(json_output)
}
