module vexecutor

import strings
import os { Result, fileno }
import freeflowuniverse.crystallib.ui.console

fn vpopen(path string) voidptr {
	// *C.FILE {
	$if windows {
		mode := 'rb'
		wpath := path.to_wide()
		return C._wpopen(wpath, mode.to_wide())
	} $else {
		cpath := path.str
		return C.popen(&char(cpath), c'r')
	}
}

fn vpclose(f voidptr) int {
	$if windows {
		return C._pclose(f)
	} $else {
		ret, _ := posix_wait4_to_exit_status(C.pclose(f))
		return ret
	}
}

fn posix_wait4_to_exit_status(waitret int) (int, bool) {
	$if windows {
		return waitret, false
	} $else {
		mut ret := 0
		mut is_signaled := true
		// (see man system, man 2 waitpid: C macro WEXITSTATUS section)
		if C.WIFEXITED(waitret) {
			ret = C.WEXITSTATUS(waitret)
			is_signaled = false
		} else if C.WIFSIGNALED(waitret) {
			ret = C.WTERMSIG(waitret)
			is_signaled = true
		}
		return ret, is_signaled
	}
}

@[manualfree]
pub fn execute_large(cmd string) Result {
	// if cmd.contains(';') || cmd.contains('&&') || cmd.contains('||') || cmd.contains('\n') {
	// return Result{ exit_code: -1, output: ';, &&, || and \\n are not allowed in shell commands' }
	// }
	pcmd := if cmd.contains('2>') { cmd.clone() } else { '${cmd} 2>&1' }
	defer {
		unsafe { pcmd.free() }
	}
	f := vpopen(pcmd)
	if isnil(f) {
		return Result{
			exit_code: -1
			output:    'exec("${cmd}") failed'
		}
	}
	fd := fileno(f)
	mut res := strings.new_builder(4096)
	defer {
		unsafe { res.free() }
	}
	buf := [8192]u8{}
	unsafe {
		pbuf := &buf[0]
		for {
			len := C.read(fd, pbuf, 8192)
			if len == 0 {
				break
			}
			res.write_ptr(pbuf, len)
		}
	}
	soutput := res.str()
	exit_code := vpclose(f)
	return Result{
		exit_code: exit_code
		output:    soutput
	}
}

pub fn execute_large_or_panic(cmd string) Result {
	res := execute_large(cmd)
	if res.exit_code != 0 {
		console.print_debug('failed    cmd: ${cmd}')
		console.print_debug('failed   code: ${res.exit_code}')
		panic(res.output)
	}
	return res
}
