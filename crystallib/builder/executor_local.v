module builder

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.rsync
// import freeflowuniverse.crystallib.core.pathlib
import os

@[heap]
pub struct ExecutorLocal {
	retry int = 1 // nr of times something will be retried before failing, need to check also what error is, only things which should be retried need to be done, default 1 because is local
pub mut:
	debug bool
}

pub fn (mut executor ExecutorLocal) exec(args ExecArgs) !string {
	res := osal.exec(cmd: args.cmd, stdout: args.stdout, debug: executor.debug)!
	return res.output
}

pub fn (mut executor ExecutorLocal) exec_interactive(args ExecArgs) ! {
	osal.execute_interactive(args.cmd)!
}

pub fn (mut executor ExecutorLocal) file_write(path string, text string) ! {
	// console.print_debug('local write ${path}')
	return os.write_file(path, text)
}

pub fn (mut executor ExecutorLocal) file_read(path string) !string {
	return os.read_file(path)
}

pub fn (mut executor ExecutorLocal) file_exists(path string) bool {
	return os.exists(path)
}

pub fn (mut executor ExecutorLocal) debug_on() {
	executor.debug = true
}

pub fn (mut executor ExecutorLocal) debug_off() {
	executor.debug = false
}

// carefull removes everything
pub fn (mut executor ExecutorLocal) delete(path string) ! {
	if os.is_file(path) || os.is_link(path) {
		return os.rm(path)
	} else if os.is_dir(path) {
		return os.rmdir_all(path)
	}
	return
}

// get environment variables from the executor
pub fn (mut executor ExecutorLocal) environ_get() !map[string]string {
	env := os.environ()
	if false {
		return error('can never happen')
	}
	return env
}

/*
Executor info or meta data
accessing type Executor won't allow to access the
fields of the struct, so this is workaround
*/
pub fn (mut executor ExecutorLocal) info() map[string]string {
	return {
		'category': 'local'
	}
}

// upload from local FS to executor FS
pub fn (mut executor ExecutorLocal) upload(args SyncArgs) ! {
	mut rsargs := rsync.RsyncArgs{
		source:         args.source
		dest:           args.dest
		delete:         args.delete
		ignore:         args.ignore
		ignore_default: args.ignore_default
		stdout:         args.stdout
	}
	rsync.rsync(rsargs)!
}

// download from executor FS to local FS
pub fn (mut executor ExecutorLocal) download(args SyncArgs) ! {
	mut rsargs := rsync.RsyncArgs{
		source:         args.source
		dest:           args.dest
		delete:         args.delete
		ignore:         args.ignore
		ignore_default: args.ignore_default
		stdout:         args.stdout
	}
	rsync.rsync(rsargs)!
}

pub fn (mut executor ExecutorLocal) shell(cmd string) ! {
	if cmd.len > 0 {
		os.execvp('/bin/bash', ["-c '${cmd}'"])!
	} else {
		os.execvp('/bin/bash', [])!
	}
}

pub fn (mut executor ExecutorLocal) list(path string) ![]string {
	if !executor.dir_exists(path) {
		panic('Dir Not found')
	}
	return os.ls(path)
}

pub fn (mut executor ExecutorLocal) dir_exists(path string) bool {
	return os.is_dir(path)
}
