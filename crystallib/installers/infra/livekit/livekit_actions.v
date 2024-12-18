module livekit

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.ui.console
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.osal.zinit
import net.http
import json
import os

const version = '1.5.1' // minimum required livekit version

struct LiveKitInstaller {
	configpath string
	nr         int
}

// get returns the LiveKit installer instance
fn get() !LiveKitInstaller {
	return LiveKitInstaller{
		configpath: os.join_path(os.home_dir(), '.livekit', 'config.yaml')
		nr:         0 // default instance number
	}
}

// checks if a certain version or above is installed
fn installed() !bool {
	res := os.execute('${osal.profile_path_source_and()} livekit-server -v')
	if res.exit_code != 0 {
		return false
	}
	r := res.output.split_into_lines().filter(it.contains('version'))
	if r.len != 1 {
		return error("couldn't parse livekit version.\n${res.output}")
	}
	installedversion := r[0].all_after_first('version')
	if texttools.version(version) != texttools.version(installedversion) {
		return false
	}
	return true
}

fn install() ! {
	console.print_header('install livekit')
	mut installer := get()!
	osal.execute_silent('
            curl -s https://livekit.io/install.sh | bash
        ')!
}

fn startupcmd() ![]zinit.ZProcessNewArgs {
	mut res := []zinit.ZProcessNewArgs{}
	mut installer := get()!
	res << zinit.ZProcessNewArgs{
		name: 'livekit'
		cmd:  'livekit-server --config ${installer.configpath} --bind 0.0.0.0'
	}

	return res
}

fn running() !bool {
	mut installer := get()!

	myport := installer.nr * 2 + 7880
	endpoint := 'http://localhost:${myport}/api/v1/health'

	response := http.get(endpoint) or {
		println('Error connecting to LiveKit server: ${err}')
		return false
	}

	if response.status_code != 200 {
		println('LiveKit server returned non-200 status code: ${response.status_code}')
		return false
	}

	health_info := json.decode(map[string]string, response.body) or {
		println('Error decoding LiveKit server response: ${err}')
		return false
	}

	if health_info['status'] != 'ok' {
		println('LiveKit server health check failed: ${health_info['status']}')
		return false
	}

	return true
}

fn start_pre() ! {
}

fn start_post() ! {
}

fn stop_pre() ! {
}

fn stop_post() ! {
}

fn destroy() ! {
	mut installer := get()!
	os.rm('
${installer.configpath}
livekit-server
')!
}
